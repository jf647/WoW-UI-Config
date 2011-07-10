#
# $Id: Clique.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Clique;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
augment data => \&augment_data;
__PACKAGE__->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';
use Digest;

use WoWUI::Config;
use WoWUI::Util 'log';

my %profiles;
my %profiledigest;

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'clique', global => 1, perchar => 0 };
}
sub BUILD
{

    my $self = shift;
    my $config = $self->config;

    WoWUI::Util::Filter::check_filter_groups( $config->{actiongroups}, $config->{actions}, 'actions' );
    
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

}

sub augment_data
{

    my $self = shift;
    my $player = shift;

    my $log = WoWUI::Util->log;

    my $config = $self->config;

    my $data;

    for my $realm( $player->realms ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars ) {
            if( exists $config->{perchar_criteria} ) {
                next unless( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{perchar_criteria} ) );
            }
            $log->debug("processing character ", $char->name);
            my $clique = $self->build_clique($char);
            if( $clique ) {
                my $key = $char->name . ' - ' . $realm->name;
                $clique->{key} = $key;
                $clique->{name} = $char->name;
                $clique->{realm} = $char->realm->name;
                for my $spec( 1, 2 ) {
                    if( my $specname = $char->spec_get($spec) ) {
                        $clique->{"spec${spec}"} = $specname;
                    }
                }
                $data->{chars}->{$key} = $clique;
            }
        }
    }

    return unless keys %$data;
    
    $data->{profiles} = \%profiles;
    
    return $data;
       
}

sub build_clique
{

    my $self = shift;
    my $char = shift;
    
    my $config = $self->config;
    my $log = WoWUI::Util->log;

    my %clique;

    # find the potential actions for this char
    my @candidates = WoWUI::Util::Filter::filter_groups( $char->flags_get('common'), $config->{actiongroups}, 'actions' );

    # repeat for each spec that the character has
    for my $spec( 1, 2 ) {
    
        next unless( $char->spec_get($spec) );

        my @actions;
        my $flags = $char->flags_get("spec${spec}");

        # find each of the binding types we need to populate
        for my $set( keys %{ $config->{bindings} } ) {
            $log->trace("processing binding set $set");
            for my $binding( keys %{ $config->{bindings}->{$set} } ) {
                if( exists $config->{bindings}->{$set}->{$binding}->{include} ) {
                    unless( WoWUI::Util::Filter::matches( $flags, $char, $config->{bindings}->{$set}->{$binding} ) ) {
                        $log->debug("not trying to match anything to binding $binding");
                        next;
                    }
                }
                my $click = $config->{bindings}->{$set}->{$binding}->{click};
                $log->trace("deciding whether to include binding $binding");
                my $foundactiontype = 0;
                my $matchedactiontype;
                for my $actiontype( keys %{ $config->{bindings}->{$set}->{$binding}->{types} } ) {
                    $log->trace("considering type $actiontype");
                    my $matches = WoWUI::Util::Filter::matches(
                        $flags,
                        $char,
                        $config->{bindings}->{$set}->{$binding}->{types}->{$actiontype},
                    );
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
                    $log->debug("finding a '$matchedactiontype' action to tie to $binding in set $set");
                    for my $action( @candidates ) {
                        $log->trace( "considering action $action" );
                        if( WoWUI::Util::Filter::matches( $flags, $char, $config->{actions}->{$action}, [ "cliqueaction:$matchedactiontype" ] ) ) {
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
                        $log->debug("picking up action $matchedaction to add to $set bound to $binding");
                        my $thisaction = clone $config->{actions}->{$matchedaction};
                        $thisaction->{set} = $set;
                        $thisaction->{binding} = $binding;
                        $thisaction->{click} = $click;
                        $thisaction->{humanclick} = $self->make_readable_click($click),
                        push @actions, $thisaction;
                    }
                }
            }
        }
        
        # determine if this profile matches one we've already built
        my $actions_digest = $self->actions_digest( \@actions );
        my $name;
        unless( exists $profiledigest{$actions_digest} ) {
            my $done = 0;
            my $i = 1;
            while( ! $done ) {
                $name = $char->class . ' ' . $i;
                if( exists $profiles{$name} ) {
                    $i++, next;
                }
                $log->debug("storing profile $name");
                $profiles{$name} = { name => $name, actions => \@actions };
                $done = 1;
            }
            $profiles{$name} = { name => $name, actions => \@actions };
            $profiledigest{$actions_digest} = $name;
        }
        else {
            $name = $profiledigest{$actions_digest};
            $log->debug("reusing profile $name")
        }
        $clique{"profile${spec}"} = $name;

    }
    
    return unless( %clique );
    
    return \%clique;

}

sub actions_digest
{

    my $self = shift;
    my $actions = shift;
    
    my $ctx = Digest->new('MD5');
    for my $action( sort { $a->{set} cmp $b->{set} || $a->{binding} cmp $b->{binding} || $a->{click} cmp $b->{click} || $a->{value} cmp $b->{value} } @$actions ) {
        $ctx->add( $action->{set} );
        $ctx->add( $action->{binding} );
        $ctx->add( $action->{click} );
        $ctx->add( $action->{type} );
        if( exists $action->{value} ) {
            $ctx->add( $action->{value} );
        }
    }
    
    return $ctx->hexdigest;

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
