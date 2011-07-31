#
# $Id$
#

package WoWUI::Module::TellMeWhen;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

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
sub BUILD
{

    my $self = shift;

    my $config = $self->config;

    $self->global( 1 );
    $self->globalpc( 1 );

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

    return $self;
    
}

sub augment_global
{

    my $self = shift;
    $self->globaldata->{pset} = $self->profileset;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
    
    my $log = WoWUI::Util->log;
    my $config = $self->config;
    
    my $profile = WoWUI::Module::TellMeWhen::Profile->new(
        config => $config,
        char => $char,
        filtergroups => $self->filtergroups,
        modoptions => $self->modoptions( $char ),
    );
    $profile->populate( config => $config, f => $f );
    if( $profile->NumGroups ) {
        my $pname = $self->profileset->store( $profile, $char->class );
        $log->debug("profile for ", $char->rname, " is $pname");
        $self->register_char( $char, $pname );
    }
    else {
        croak $char->rname, " has TellMeWhen enabled but generated no groups";
    }

}

# keep require happy
1;

#
# EOF
