#
# $Id: Group.pm 5029 2011-06-06 07:01:30Z james $
#

package WoWUI::Module::TellMeWhen::Group;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has modoptions => ( is => 'rw', isa => 'HashRef', required => 1 );
has Enabled => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has OnlyInCombat => ( is => 'rw', isa => 'Bool', default => 0 );
has Locked => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has View => ( is => 'rw', isa => 'Str', default => 'icon', traits => ['Relevant'], relevant => 1 );
has Name => ( is => 'rw', isa => 'Str', traits => ['Relevant'], relevant => 1 );
has Strata => ( is => 'rw', isa => 'Str', default => 'MEDIUM', traits => ['Relevant'], relevant => 1 );
has Scale => ( is => 'rw', isa => 'Num', default => 2, traits => ['Relevant'], relevant => 1 );
has Level => ( is => 'rw', isa => 'Int', default => 10, traits => ['Relevant'], relevant => 1 );
has Rows => ( is => 'rw', isa => 'Int', traits => ['Relevant'], relevant => 1 );
has Columns => ( is => 'rw', isa => 'Int', traits => ['Relevant'], relevant => 1 );
has CheckOrder => ( is => 'rw', isa => 'Int', default => -1, traits => ['Relevant'], relevant => 1 );
has PrimarySpec => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has SecondarySpec => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has LayoutDirection => ( is => 'rw', isa => 'Num', default => 1, traits => ['Relevant'], relevant => 1 );
has Tree1 => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has Tree2 => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has Tree3 => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has Tree4 => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has SortPriorities => (
    is => 'rw',
    isa => 'ArrayRef[HashRef]',
    default => sub { [
        { Method => 'id', Order => 1 },
        { Method => 'duration', Order => 1 },
        { Method => 'stacks', Order => -1 },
        { Method => 'visiblealpha', Order => -1 },
        { Method => 'visibleshown', Order => -1 },
        { Method => 'alpha', Order => -1 },
        { Method => 'shown', Order => -1 },
        
    ] },
    traits => ['Relevant'],
    relevant => 1,
);
has Point => ( is => 'rw', isa => 'WoWUI::Module::TellMeWhen::Point', traits => ['Relevant'], relevant => 1 );
has SettingsPerView => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    traits => ['Relevant'],
    relevant => 1,
);
has Icons => (
    is => 'ro',
    isa => 'ArrayRef[WoWUI::Module::TellMeWhen::Icon]',
    traits => ['Array','Relevant'],
    relevant => 1,
    default => sub { [] },
    handles => {
        add_icon => 'push',
        icon_count => 'count',
    },
);
has Conditions => (
    is => 'ro',
    isa => 'WoWUI::Module::TellMeWhen::ConditionSet',
    traits => ['Relevant'],
    relevant => 1,
    default => sub { WoWUI::Module::TellMeWhen::ConditionSet->new },
    handles => [ qw|add_cond cond_count cond_values unshift_cond| ],
);
CLASS->meta->make_immutable;

use Carp 'croak';

# populate a group with icons
sub populate
{

    my $self = shift;
    my($profile, $i, $name, $spec, $combat) = @_;

    my $log = WoWUI::Util->log;
    
    # set name
    if( 'hidden' eq $name ) {
        $self->Name("Spec $spec hidden Combat $combat");
    }
    else {
        $self->Name("Spec $spec Combat $combat");
    }

    # insert icons
    $self->add_icon( @{ $i->{$name}->{$spec}->{$combat} } );

    # set number of columns and rows
    if( $self->icon_count > $self->modoptions->{maxpergroup} ) {
        $self->Columns( $self->modoptions->{maxpergroup} );
        $self->Rows( int( $self->icon_count / $self->modoptions->{maxpergroup} ) + 1 );
    }
    else {
        $self->Columns( $self->icon_count );
        $self->Rows( 1 );
    }
    $log->debug("group has ", $self->Columns, " columns and ", $self->Rows, " rows");

    # choose group position
    my $gpoint;
    if( 2 == $spec ) {
        # spec 2 groups overlap their spec 1 counterparts (if they exist)
        if( $gpoint = $profile->groupspec_get("$name/1/$combat") ) {
            $log->trace("reusing position of $name/1/$combat");
        }
    }
    unless( $gpoint ) {
        $log->trace("choosing next available group position");
        # otherwise we need to use the next available position
        $gpoint = $profile->nextgrouppos->meta->clone_object( $profile->nextgrouppos );
        # bump the next available position down
        $profile->nextgrouppos->y_down( $self->Rows * $self->modoptions->{groupspacing} );
    }
    $self->Point( $gpoint );
    $log->debug("group position is ", $self->Point->x, "/", $self->Point->y);
    
    # add a condition to in combat groups 
    if( 'in' eq $combat ) {
        $self->add_cond( WoWUI::Module::TellMeWhen::Condition->new( tag => 'ic', Type => 'COMBAT' ) );
    }
    
    # add a condition to spec specific groups
    if( 0 != $spec ) {
        $self->add_cond( WoWUI::Module::TellMeWhen::Condition->new( tag => "spec$spec", Type => 'SPEC', Level => $spec ) );
        if( 1 == $spec ) {
            $self->SecondarySpec( 0 );
        }
        else {
            $self->PrimarySpec( 0 );
        }
    }
    
    # set fake hidden on icons in hidden groups
    if( 'hidden' eq $name ) {   
        $_->FakeHidden( 1 ) for( @{ $self->Icons } );
    }
    
    # add the group to the profile and remember how to get at it by reference
    $profile->add_group( $self );
    $profile->groupspec_set("$name/$spec/$combat", $self->Point );
    
    # remember the position of each icon in the group
    my($g, $p) = ( $profile->NumGroups, 1 );
    for my $icon( @{ $self->Icons } ) {
        $profile->iconpos_set( $icon->tag, [ $g, $p ] );
        $log->trace("iconpos: ", $icon->tag, " $g/$p");
        $p++;
    }

}

sub fixup
{

    my $self = shift;
    my $profile = shift;
    
    if( $self->Columns > $profile->widestgroup ) {
        $profile->widestgroup( $self->Columns );
    }

}

sub setscale
{

    my $self = shift;
    my $profile = shift;
    
    $self->Scale( $profile->groupscale );

}

sub augment_lua { '' }

# keep require happy
1;

#
# EOF
