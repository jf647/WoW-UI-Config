#
# $Id: Rotation.pm 5014 2011-05-30 11:38:15Z james $
#

package WoWUI::Module::TellMeWhen::Group::Rotation;
use Moose;

use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
extends 'WoWUI::Module::TellMeWhen::Group';
around fixup => sub {}; # no-pp behaviour of parent
around setscale => sub {}; # no-pp behaviour of parent
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

# populate a rotation group
sub populate
{

    my $self = shift;
    my($profile, $spec, $r) = @_;

    my $log = WoWUI::Util->log;

    # set name
    $self->Name("Spec $spec Rotation");

    # add just the icon object for the rotation (which must be a meta)
    my $metaicon = WoWUI::Module::TellMeWhen::Icons->instance->icon_get( $r->{icon} )->clone;
    unless( $metaicon ) {
        croak "cannot get rotation icon $r->{icon}";
    }
    unless( $metaicon->isa( 'WoWUI::Module::TellMeWhen::Icon::Meta' ) ) {
        croak "rotation icons must be of type Meta";
    }
    $self->add_icon( $metaicon );
    
    # add in any icons the meta needs
    my $hidden = Set::Scalar->new;
    $metaicon->select_extra($hidden);
    for my $iname( $hidden->members ) {
        # only add icons that aren't already selected (which should be all, but you never know...)
        unless( $profile->iconpos_exists( $iname ) ) {
            my $icon = WoWUI::Module::TellMeWhen::Icons->instance->icon_get( $iname )->clone;
            croak "cannot get rotation icon $iname" unless( $icon );
            $icon->FakeHidden( 1 );
            $self->add_icon( $icon );
        }
    }

    # rotations are fixed at 5 wide, just because
    if( $self->icon_count > 5 ) {
        $self->Columns( 5 );
        $self->Rows( int( $self->icon_count / 5 ) + 1 );
    }
    else {
        $self->Columns( $self->icon_count );
        $self->Rows( 1 );
    }

    # choose group position
    my $gpoint;
    if( 2 == $spec ) {
        # spec 2 groups overlap their spec 1 counterparts (if they exist)
        if( $gpoint = $profile->groupspec_get("rotation/1") ) {
            $log->trace("reusing position of rotation/1");
        }
    }
    unless( $gpoint ) {
        $gpoint = WoWUI::Module::TellMeWhen::Point->new( $r->{anchor} );
    }
    $self->Point( $gpoint );
    
    # rotation groups are always in combat
    $self->add_cond( WoWUI::Module::TellMeWhen::Condition->new( tag => 'ic', Type => 'COMBAT' ) );
    
    # add a spec specific condition
    $self->add_cond( WoWUI::Module::TellMeWhen::Condition->new( tag => "spec$spec", Type => 'SPEC', Level => $spec ) );
    if( 1 == $spec ) {
        $self->SecondarySpec( 0 );
    }
    else {
        $self->PrimarySpec( 0 );
    }

    # add the group to the profile and remember how to get at it by reference
    $profile->add_group( $self );
    $profile->groupspec_set("rotation/$spec", $self->Point );
    
    # remember the position of each icon in the group
    my($g, $p) = ( $profile->NumGroups, 1 );
    for my $icon( @{ $self->Icons } ) {
        $profile->iconpos_set( $icon->tag, [ $g, $p ] );
        $p++;
    }

}

# keep require happy
1;

#
# EOF
