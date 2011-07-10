#
# $Id$
#

package WoWUI::Module::TellMeWhen;
use Moose;

use namespace::autoclean;

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
augment data => \&augment_data;
augment chardata => \&augment_chardata;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Clone 'clone';
use Data::Compare;
use Digest;
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util 'log';

use WoWUI::Filter;
use WoWUI::FilterGroups;
use WoWUI::ProfileSet;

use WoWUI::Module::TellMeWhen::Group;
use WoWUI::Module::TellMeWhen::Group::Rotation;
use WoWUI::Module::TellMeWhen::Conditions;
use WoWUI::Module::TellMeWhen::Events;
use WoWUI::Module::TellMeWhen::Icon;
use WoWUI::Module::TellMeWhen::Profile;
use WoWUI::Module::TellMeWhen::Point;
use WoWUI::Module::TellMeWhen::Icons;
use WoWUI::Module::TellMeWhen::Icon::Meta;
use WoWUI::Module::TellMeWhen::Icon::Reactive;
use WoWUI::Module::TellMeWhen::Icon::Cooldown;
use WoWUI::Module::TellMeWhen::Icon::Cooldown::Item;
use WoWUI::Module::TellMeWhen::Icon::Cooldown::Multistate;
use WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell;
use WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal;
use WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal::Item;
use WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal::Spell;
use WoWUI::Module::TellMeWhen::Icon::Totem;
use WoWUI::Module::TellMeWhen::Icon::Aura;
use WoWUI::Module::TellMeWhen::Icon::Buff;
use WoWUI::Module::TellMeWhen::Icon::Debuff;
use WoWUI::Module::TellMeWhen::Condition;
use WoWUI::Module::TellMeWhen::Condition::Icon;
use WoWUI::Module::TellMeWhen::Condition::Runes;

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'tmw', global => 1, perchar => 1 };
}
sub BUILD
{

    my $self = shift;

    my $config = $self->config;

    # build filter groups
    my $fgs = WoWUI::FilterGroups->new(
        $config->{filtergroups},
        $config->{icons},
    );
    $self->filtergroups( $fgs );

    # instantiate conditions singleton
    WoWUI::Module::TellMeWhen::Conditions->initialize( config => $config );

    # instantiate icons singleton
    WoWUI::Module::TellMeWhen::Icons->initialize( config => $config );
    
}

sub augment_chardata
{

    my $self = shift;
    my $char = shift;
    
    return { realm => $char->realm->name, name => $char->name };

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
            my $f = WoWUI::Filter->new( char => $char );
            if( exists $config->{perchar_criteria} ) {
                next unless( $f->match( $config->{perchar_criteria} ) );
            }
            $log->debug("processing character ", $char->name);
            my $profile = WoWUI::Module::TellMeWhen::Profile->new(
                config => $config,
                char => $char,
                filtergroups => $self->filtergroups,
            );
            $profile->populate( config => $config, f => $f );
            if( $profile->NumGroups ) {
                my $pname = $self->profileset->store( $profile, $char->class );
                $log->debug("profile for ", $char->name, " of ", $realm->name, " is $pname");
                $data->{realms}->{$realm->name}->{$char->name} = $pname;
            }
            else {
                croak $char->name, " of ", $realm->name, " has TellMeWhen enabled but generated no groups";
            }
        }
    }
    
    $data->{pset} = $self->profileset;
    
    return $data;

}

# keep require happy
1;

#
# EOF
