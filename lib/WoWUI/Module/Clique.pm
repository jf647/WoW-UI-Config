#
# $Id: Clique.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Clique;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

use WoWUI::ProfileSet;

# set up class
extends 'WoWUI::Module::Base';
has filtergroups => (
    is => 'rw',
    isa => 'WoWUI::FilterGroups',
);
has profileset => (
    is => 'rw',
    isa => 'WoWUI::ProfileSet',
    default => sub { WoWUI::ProfileSet->new },
);
CLASS->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';
use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->global( 1 );
    $self->globalpc( 1 );

    my $config = $self->config;    

    # build filter groups
    my $fgs = WoWUI::FilterGroups->new(
        $config->{filtergroups},
        $config->{actions},
    );
    $self->filtergroups( $fgs );
    
    for my $action( keys %{ $config->{actions} } ) {
        unless( exists $config->{actions}->{$action}->{type} ) {
            $config->{actions}->{$action}->{type} = 'spell';
        }
        if( 'spell' eq $config->{actions}->{$action}->{type} ) {
            if( exists $config->{actions}->{$action}->{spell} ) {
                $config->{actions}->{$action}->{value} = $config->{actions}->{$action}->{spell};
            }
            else {
                $config->{actions}->{$action}->{value} = $action;
            }
            delete $config->{actions}->{$action}->{spell};
        }
        elsif( 'macro' eq $config->{actions}->{$action}->{type} ) {
            $config->{actions}->{$action}->{value} = $config->{actions}->{$action}->{macro};
            delete $config->{actions}->{$action}->{macro};
        }
    }
    
    return $self;

}

sub augment_global
{

    my $self = shift;
    $self->globaldata->{pset} = $self->profileset;
    
    return;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
    
    my $log = WoWUI::Util->logger;

    my $clique = $self->build_clique($char, $f);
    if( $clique ) {
        $self->globaldata->{chars}->{$char->dname} = $clique;
    }
    else {
        $log->warn($char->rname, " has Clique enabled but produced an empty profile");
    }
    
    return;
       
}

sub build_clique
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
    
    my $config = $self->modconfig( $char );
    my $log = WoWUI::Util->logger;

    my %clique;

    # find the potential actions for this char
    my $candidates = $self->filtergroups->candidates($f);
    $log->trace("candidates are $candidates");

    # repeat for each spec that the character has
    for my $spec( 1, 2 ) {
    
        next unless( $char->spec_get($spec) );
        my $using;
        if( 1 == $spec ) {
            $using = F_C0|F_C1;
        }
        else {
            $using = F_C0|F_C2;
        }

        # find each of the binding types we need to populate
        my @actions;
        for my $bindingset( keys %{ $config->{bindings} } ) {
            $log->trace("processing binding set $bindingset");
            for my $binding( keys %{ $config->{bindings}->{$bindingset} } ) {
                if( exists $config->{bindings}->{$bindingset}->{$binding}->{filter} ) {
                    unless( $f->match( $config->{bindings}->{$bindingset}->{$binding}->{filter}, $using ) ) {
                        $log->debug("not trying to match anything to binding $binding");
                        next;
                    }
                }
                my $click = $config->{bindings}->{$bindingset}->{$binding}->{click};
                $log->trace("deciding whether to include binding $binding");
                my $foundactiontype = 0;
                my $matchedactiontype;
                for my $actiontype( keys %{ $config->{bindings}->{$bindingset}->{$binding}->{types} } ) {
                    my $matches = 0;
                    if( exists $config->{bindings}->{$bindingset}->{$binding}->{types}->{$actiontype}->{filter} ) {
                        if( $f->match( $config->{bindings}->{$bindingset}->{$binding}->{types}->{$actiontype}->{filter}, $using ) ) {
                            $matches = 1;
                        }
                    }
                    else {
                        $matches = 1;
                    }
                    if( $matches ) {
                        if( 1 == $foundactiontype ) {
                            croak "binding $binding matched $actiontype after matching $matchedactiontype";
                        }
                        $log->trace("$actiontype matches");
                        $foundactiontype = 1;
                        $matchedactiontype = $actiontype;
                    }
                    else {
                        $log->trace("$actiontype does not match");
                    }
                }
                if( 1 == $foundactiontype ) {
                    my $foundaction = 0;
                    my $matchedaction;
                    $log->debug("finding a '$matchedactiontype' action to tie to $binding in set $bindingset");
                    for my $action( @$candidates ) {
                        if( $f->match( $config->{actions}->{$action}->{filter}, $using, "cliqueaction:$matchedactiontype" ) ) {
                            if( 1 == $foundaction ) {
                                croak "$matchedactiontype matched $action after matching $matchedaction";
                            }
                            $log->trace("$action matched type $matchedactiontype");
                            $foundaction = 1;
                            $matchedaction = $action
                        }
                        else {
                            $log->trace("$action did not match $matchedactiontype");
                        }
                    }
                    if( 1 == $foundaction ) {
                        $log->debug("picking up action $matchedaction to add to $bindingset bound to $binding");
                        my $thisaction = clone $config->{actions}->{$matchedaction};
                        $thisaction->{set} = $bindingset;
                        $thisaction->{binding} = $binding;
                        $thisaction->{click} = $click;
                        $thisaction->{humanclick} = $self->make_readable_click($click);
                        push @actions, $thisaction;
                    }
                }
            }
        }
        
        # determine if this profile matches one we've already built
        my $pname = $self->profileset->store( { actions => \@actions }, $char->class );
        $log->debug("profile for ", $char->rname, " is $pname");
        $clique{"profile${spec}"} = $pname;

    }

    return unless( %clique );

    $clique{key} = $char->dname;
    $clique{name} = $char->name;
    $clique{realm} = $char->realm->name;
    for my $spec( 1, 2 ) {
        if( my $specname = $char->spec_get($spec) ) {
            $clique{"spec${spec}"} = $specname;
        }
    }
    
    return \%clique;

}

sub make_readable_click
{

    my $self = shift;
    my $click = shift;

    $click =~ s/SHIFT/Shift/;    
    $click =~ s/ALT/Alt/;
    $click =~ s/CTRL/Control/;
    $click =~ s/BUTTON1/Left/;
    $click =~ s/BUTTON2/Right/;
    $click =~ s/BUTTON3/Middle/;
    
    return $click;
    
}

# keep require happy
1;

#
# EOF
