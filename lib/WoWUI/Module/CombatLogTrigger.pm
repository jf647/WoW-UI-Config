#
# $Id: CombatLogTrigger.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Module::CombatLogTrigger;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Carp 'croak';
use Clone 'clone';

use WoWUI::Config;
use WoWUI::Util 'log';
use WoWUI::Filter::Constants;

# group type bitmask
my %groupmask = (
    'solo'  => 0x01,
    'party' => 0x02,
    'raid'  => 0x04,
    'bg'    => 0x08,
    'arena' => 0x10,
);

sub BUILD
{

    my $self = shift;

    $self->perchar( 1 );
    
    return $self;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $log = WoWUI::Util->logger;

    my $config = $self->modconfig( $char );
    my $o = $self->modoptions( $char );

    my $chardata = { enabled => $o->{enabled}, debug => $o->{debug} };

    my %specs;
    if( $char->spec_get(1) && $char->spec_get(2) ) {
        %specs = ( 1 => 'spec1', 2 => 'spec2' );
    }
    elsif( $char->spec_get(1) ) {
        %specs = ( 1 => 'spec1' );
    }
    else {
        %specs = ( 1 => 'common' );
    }

    for my $specnum( sort keys %specs ) {
        my $using;
        if( 1 == $specnum ) {
            $using = F_C0|F_C1;
        }
        else {
            $using = F_C0|F_C2;
        }
        $log->debug("processing spec $specnum");
        my @triggers;
        for my $tname( keys %{ $config->{triggers} } ) {
            $log->debug("considering trigger $tname");
            my $trigger = $config->{triggers}->{$tname};
            if( $f->match( $trigger->{filter}, $using ) ) {
                $log->debug("trigger matched");
                push @triggers, $self->make_trigger($char, $tname);
            }
        }
        $chardata->{triggers}->{$specnum} = \@triggers;
    }

    $self->perchardata( $chardata );

}

# make a trigger
sub make_trigger
{

    my $self = shift;
    my $char = shift;
    my $tname = shift;

    my $config = $self->modconfig( $char );
    my $trigger = $config->{triggers}->{$tname};
    
    my $t = { name => $tname };

    # spellid reporting
    if( exists $trigger->{reportspellid} ) {
        $t->{reportspellid} = 1;
    }

    # channel / affiliation
    $t->{channel} = $trigger->{channel} || 'AUTO';
    $t->{affiliation} = $trigger->{affiliation} || "mine";

    # grouptype
    my @grouptype;
    if( exists $trigger->{grouptype} ) {
        @grouptype = @{ $trigger->{grouptype} };
    }
    else {
        @grouptype = qw|party raid|;
    }
    $t->{groupmask} = 0;
    for my $grouptype( @grouptype ) {
        $t->{groupmask} |= $groupmask{$grouptype};
    }
    
    # combat
    my $incombat;
    if( exists $trigger->{combateither} ) {
        # noop
    }
    elsif( exists $trigger->{incombat} ) {
        $t->{incombat} = $trigger->{incombat};
    }
    else {
        $t->{incombat} = 1;
    }
    
    # source / dest
    $t->{src} = $t->{src} || $char->name;
    if( exists $trigger->{notonself} ) {
        $t->{notonself} = 1;
    }
    elsif( exists $trigger->{dst} ) {
        $t->{dst} = $t->{dst};
    }
    
    # set spell
    if( exists $trigger->{anyspell} ) {
          $t->{anyspell} = 1;
    }
    elsif( exists $trigger->{spellId} ) {
        $t->{spellId} = $trigger->{spellId};
    }
    elsif( exists $trigger->{spellName} ) {
        $t->{spellName} = $trigger->{spellName};
    }
    else {
        $t->{spellName} = $tname;
    }
    
    # approx spell
    if( exists $t->{spellName} && exists $trigger->{matchapprox} ) {
        $t->{spellApprox} = $t->{spellName};
        delete $t->{spellName};
    }
    
    # branch based on type
    my @triggers;
    if( 'buff' eq $trigger->{type} ) {
        $t->{message} =  $trigger->{message_up} || "*slink up";
        $t->{event} = 'SPELL_AURA_APPLIED';
        push @triggers, $t;
        unless( exists $trigger->{uponly} ) {
            my $t2 = clone $t;
            $t2->{event} = 'SPELL_AURA_REMOVED';
            $t2->{message} =  $trigger->{message_down} || "*slink down";
            push @triggers, $t2
        }
    }
    elsif( 'interrupt' eq $trigger->{type} ) {
        $t->{message} =  $trigger->{message} || "Interrupted: *eslink (*tgt*rtls)";
        $t->{event} = 'SPELL_INTERRUPT';
        $t->{hasespellid} = 1;
        $t->{replacert} = 1;
        push @triggers, $t;
    }
    elsif( 'spell' eq $trigger->{type} ) {
        $t->{message} = $trigger->{message} || "*slink on *tgt";
        $t->{event} = 'SPELL_CAST_SUCCESS';
        push @triggers, $t;
    }
    elsif( 'debuff' eq $trigger->{type} ) {
        $t->{message} = $trigger->{message} || "*slink on *tgt*rtpls";
        $t->{event} = 'SPELL_AURA_APPLIED';
        $t->{replacert} = 1;
        $t->{affiliation} = $trigger->{affiliation} || 'enemy';
        delete $t->{incombat};
        push @triggers, $t;
        if( exists $trigger->{reportrefresh} ) {
            my $t2 = clone $t;
            $t2->{event} = 'SPELL_AURA_REFRESH';
            $t2->{message} = $trigger->{message_refresh} || "*slink on *tgt*rtpbs refreshed";
            push @triggers, $t2;
        }
        if( exists $trigger->{reportfade} ) {
            my $t2 = clone $t;
            $t2->{event} = 'SPELL_AURA_REMOVED';
            $t2->{message} = $trigger->{message_removed} || "*slink on *tgt*rtpbs faded";
            push @triggers, $t2;
        }
        if( exists $trigger->{reportbreak} ) {
            my $t2 = clone $t;
            $t2->{event} = 'SPELL_AURA_BROKEN';
            $t2->{message} = $trigger->{message_broken} || "*slink on *tgt*rtpbs broken by *src";
            push @triggers, $t2;
            my $t3 = clone $t;
            $t3->{event} = 'SPELL_AURA_BROKEN_SPELL';
            $t3->{message} = $trigger->{message_broken} || "*slink on *tgt*rtpbs broken by *src's *eslink";
            $t3->{hasespellid} = 1;
            push @triggers, $t3;
        }
    }
    elsif( 'spellfailed' eq $trigger->{type} ) {
        $t->{message} = $trigger->{message} || "*slink failed on *tgt";
        $t->{event} = 'SPELL_MISSED';
        push @triggers, $t;
    }
    elsif( 'totem' eq $trigger->{type} ) {
        $t->{message} = $trigger->{message_summon} || "dropped *slink";
        $t->{event} = 'SPELL_SUMMON';
        unless( $trigger->{summononly} ) {
            my $t2 = clone $t;
            $t->{affiliation} = 'mine';
            $t2->{src} = $t2->{spellName};
            delete $t2->{spellName};
            $t2->{anyspell} = 1;
            $t2->{event} = 'UNIT_DESTROYED';
            $t2->{affiliation} = 'myGuardian';
            $t2->{message} = $trigger->{message_destroy} || "$tname destroyed";
            push @triggers, $t2;
        }
        push @triggers, $t;
    }
    elsif( 'dispel' eq $trigger->{type} ) {
        $t->{message} = $trigger->{message} || "Dispel: *eslink (*tgt*rtls)";
        $t->{affiliation} = 'enemy';
        $t->{event} = 'SPELL_DISPEL';
        $t->{replacert} = 1;
        $t->{hasespellid} = 1;
        push @triggers, $t;
    }
    elsif( 'steal' eq $trigger->{type} ) {
        $t->{message} = $trigger->{message} || "Stole: *eslink (*tgt*rtls)";
        $t->{affiliation} = 'enemy';
        $t->{event} = 'SPELL_STOLEN';
        $t->{replacert} = 1;
        $t->{hasespellid} = 1;
        push @triggers, $t;
    }
    elsif( 'create' eq $trigger->{type} ) {
        $t->{message} = $trigger->{message} || "*src has cast *slink";
        $t->{event} = 'SPELL_CREATE';
        push @triggers, $t;
    }
    else {
        croak "unknown trigger type '$trigger->{type}'";
    }
    
    return @triggers;
  
}

# keep require happy
1;

#
# EOF
