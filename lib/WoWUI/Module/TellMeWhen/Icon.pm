#
# $Id: Icon.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
# internal
has tmw => ( is => 'rw', isa => 'WoWUI::Module::TellMeWhen', weak_ref => 1 );
has profile => ( is => 'rw', isa => 'WoWUI::Module::TellMeWhen::Profile', weak_ref => 1 );
has priority => ( is => 'rw', isa => 'Int', required => 1 );
has tag => ( is => 'rw', isa => 'Str' );
has combat => ( is => 'rw', isa => 'Str' );
has filter => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has no_filter_group_ok => ( is => 'ro', isa => 'Bool' );
has type => ( is => 'ro', isa => 'Str' );
has conditions => ( is => 'ro', isa => 'ArrayRef' );
# String, no default, not relevant
has [ qw|BuffOrDebuff CooldownType| ] => ( is => 'rw', isa => 'Str', traits => ['Relevant'] );
# String, no default, relevant
has Name => ( is => 'rw', isa => 'Str', required => 1, lazy => 1, builder => 'build_name', traits => ['Relevant'], relevant => 1 );
# String, other
has ShowWhen => ( is => 'rw', isa => 'Str', default => 'alpha', traits => ['Relevant'] );
has Type => ( is => 'rw', isa => 'Str', required => 1, traits => ['Relevant'], relevant => 1 );
has Unit => ( is => 'rw', isa => 'Str', default => 'player', traits => ['Relevant'] );
has WpnEnchantType => ( is => 'rw', isa => 'Str', default => 'MainHandSlot', traits => ['Relevant'] );
has ICDType => ( is => 'rw', isa => 'Str', default => 'aura', traits => ['Relevant'] );
has TotemSlots => ( is => 'rw', isa => 'Str', default => '1111', traits => ['Relevant'] );
has CustomTex => ( is => 'rw', isa => 'Str', default => "", traits => ['Relevant'], relevant => 1 );
has BindText => ( is => 'rw', isa => 'Str', default => "", traits => ['Relevant'], relevant => 1 );
# Boolean, default true, relevant
has [ qw|Enabled ShowTimerText| ] => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
# Boolean, default true, not relevant
has [ qw|OnlyMine SortAsc SortDesc| ] => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'] );
# Boolean, default false, relevant
has [ qw|
    ShowTimer InvertBars ShowCBar
    FakeHidden DurationMinEnabled DurationMaxEnabled
| ] => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
# Boolean, default false, not relevant
has [ qw|
    RangeCheck ManaCheck CooldownCheck
    IgnoreRunes CheckNext OnlyEquipped
    OnlyInBags OnlySeen UseActvtnOverlay
    HideUnequipped Interruptible StackMinEnabled
    StackMaxEnabled ShowPBar Sort
| ] => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
# Int / Num
has ConditionAlpha => ( is => 'rw', isa => 'Num', default => 0, traits => ['Relevant'], relevant => 1 );
has CBarOffs => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'], relevant => 1 );
has PBarOffs => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'] );
has [ qw|Alpha UnAlpha| ] => ( is => 'rw', isa => 'Num', default => 1, traits => ['Relevant'], relevant => 1 );
has [ qw|StackMin StackMax| ] => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'] );
has [ qw|DurationMin DurationMax| ] => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'], relevant => 1 );
# Other
has Events => (
    is => 'rw',
    isa => 'WoWUI::Module::TellMeWhen::Events',
    default => sub { WoWUI::Module::TellMeWhen::Events->new },
    traits => ['Relevant'],
    relevant => 1,
);
has Icons => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    traits => ['Array','Relevant'],
    default => sub { [] },
    handles => {
        add_metaicon => 'push',
        metaicon_count => 'count',
    },
);
has Conditions => (
    is => 'rw',
    isa => 'ArrayRef[WoWUI::Module::TellMeWhen::Condition]',
    traits => ['Array','Relevant'],
    relevant => 1,
    default => sub { [] },
    handles => {
        add_cond => 'push',
        unshift_cond => 'unshift',
        cond_count => 'count',
    },
);
CLASS->meta->make_immutable;

use Carp 'croak';
use Scalar::Util 'reftype';

# constructor
sub BUILD
{

    my $self = shift;

    # set our name to our tag unless a subclass did it for us
    unless( $self->Name ) {
        $self->Name( $self->tag );
    }

    if( $self->conditions ) {
        my @conditions;
        unless( @{ $self->conditions } % 2 ) {
            croak "even number of conditions in icon ", $self->Name;
        }
        my $needs_join = 0;
        while( @{ $self->conditions } ) {
            my $condition = shift @{ $self->conditions };
            if( $needs_join ) {
                if( 'OR' eq $condition ) {
                    $conditions[$#conditions]->{AndOr} = 'OR';
                }
                elsif( 'AND' eq $condition ) {
                    $conditions[$#conditions]->{AndOr} = 'AND';
                }
                else {
                    croak "invalid condition conjunction '$condition'";
                }
                $needs_join = 0;
            }
            else {
                my $c;
                if( 'HASH' eq ref $condition ) {
                    my $cs = $self->tmw->conditions;
                    my $cname = $cs->nextanon;
                    $c = WoWUI::Module::TellMeWhen::Condition->new(
                        tag => $cname,
                        Name => $cname,
                        %$condition
                    );
                    $self->tmw->conditions->set( $cname, $c );
                }
                elsif( $condition =~ m/^icon:(.+)/ ) {
                    $c = WoWUI::Module::TellMeWhen::Condition::Icon->new( tag => $1, Icon => $1 );
                }
                else {
                    $c = $self->tmw->conditions->get( $condition );
                }
                die "invalid condition '$condition'" unless $c;
                push @conditions, $c;
                $needs_join = 1;
            }
        }
        $self->add_cond( @conditions );
    }    

    return $self;

}

# builder for our Name
sub build_name
{

    my $self = shift;
    $self->Name( $self->tag );

}

# custom clone
sub clone
{

    my $self = shift;
    
    return $self->meta->clone_object(
        $self, Conditions => [ @{ $self->Conditions } ],
    );

}

sub augment_lua { '' }

sub select_extra
{

    my($self, $set) = @_;

    my $log = WoWUI::Util->log;
    
    # add icons that are part of conditions to the hidden set
    if( $self->cond_count ) {
        for my $cond( @{ $self->Conditions } ) {
            if( 'WoWUI::Module::TellMeWhen::Condition::Icon' eq blessed($cond) ) {
                $log->trace("adding hidden ", $cond->Icon);
                $set->insert( $cond->Icon );
            }
        }
    }
    # allow subclasses to do their own thing
    inner();
    
}

sub fixup
{

    my($self, $profile) = @_;

    my @newc;
    for my $cond( @{ $self->Conditions } ) {
        if( 'WoWUI::Module::TellMeWhen::Condition::Icon' eq blessed($cond) ) {
            my $iconpos = $profile->iconpos_get( $cond->Icon );
            unless( $iconpos ) {
                croak "can't find an icon position for ", $cond->Icon;
            }
            push @newc, WoWUI::Module::TellMeWhen::Condition->new(
                tag => "$iconpos->[0]_$iconpos->[1]_shown",
                Type => 'ICON',
                Icon => 'TellMeWhen_Group' . $iconpos->[0] . '_Icon' . $iconpos->[1],
                Level => $cond->Level,
            );
        }
        else {
            push @newc, $cond;
        }
    }
    $self->Conditions( \@newc );
    
    # allow the subclass to do their own thing
    inner();

}

# keep require happy
1;

#
# EOF
