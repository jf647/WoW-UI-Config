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
has priority => ( is => 'rw', isa => 'Int', required => 1 );
has tag => ( is => 'rw', isa => 'Str' );
has combat => ( is => 'rw', isa => 'Str' );
has filter => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has no_filter_group_ok => ( is => 'ro', isa => 'Bool' );
has type => ( is => 'ro', isa => 'Str' );
has conditions => ( is => 'ro', isa => 'ArrayRef' );
has ShowWhen => ( is => 'rw', isa => 'Num', default => 0x2, traits => ['Relevant'] );
has Enabled => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has Name => ( is => 'rw', isa => 'Str', required => 1, lazy_build => 1, traits => ['Relevant'], relevant => 1 );
has Type => ( is => 'rw', isa => 'Str', required => 1, traits => ['Relevant'], relevant => 1 );
has Alpha => ( is => 'rw', isa => 'Num', default => 1, traits => ['Relevant'], relevant => 1 );
has UnAlpha => ( is => 'rw', isa => 'Num', default => 1, traits => ['Relevant'], relevant => 1 );
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
has SettingsPerView => (
    is => 'rw',
    isa => 'WoWUI::Module::TellMeWhen::RawLua',
    traits => ['Relevant'],
    relevant => 1,
    lazy_build => 1,
);
has Conditions => (
    is => 'ro',
    isa => 'WoWUI::Module::TellMeWhen::ConditionSet',
    traits => ['Relevant'],
    relevant => 1,
    default => sub { WoWUI::Module::TellMeWhen::ConditionSet->new },
    handles => [ qw|add_cond cond_count cond_values unshift_cond| ],
);
has Events => (
    is => 'rw',
    isa => 'WoWUI::Module::TellMeWhen::Events',
    default => sub { WoWUI::Module::TellMeWhen::Events->new },
    traits => ['Relevant'],
    relevant => 1,
);
has BindText => ( is => 'rw', isa => 'Str', default => "", traits => ['Relevant'], relevant => 1 );
has BuffOrDebuff => ( is => 'rw', isa => 'Str', traits => ['Relevant'] );
has CBarOffs => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'], relevant => 1 );
has CheckNext => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has ConditionAlpha => ( is => 'rw', isa => 'Num', default => 0, traits => ['Relevant'], relevant => 1 );
has CooldownCheck => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has CooldownType => ( is => 'rw', isa => 'Str', traits => ['Relevant'] );
has CustomTex => ( is => 'rw', isa => 'Str', default => "", traits => ['Relevant'], relevant => 1 );
has DurationMax => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'], relevant => 1 );
has DurationMaxEnabled => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has DurationMin => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'], relevant => 1 );
has DurationMinEnabled => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has EnableStacks => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has FakeHidden => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has HideUnequipped => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has ICDType => ( is => 'rw', isa => 'Str', default => 'aura', traits => ['Relevant'] );
has IgnoreRunes => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has Interruptible => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has InvertBars => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has ManaCheck => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has OnlyEquipped => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has OnlyInBags => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has OnlyMine => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'] );
has OnlySeen => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has PBarOffs => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'] );
has RangeCheck => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has ShowCBar => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has ShowPBar => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has ShowTimer => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has ShowTimerText => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has Sort => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has SortAsc => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'] );
has SortDesc => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'] );
has StackMax => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'] );
has StackMaxEnabled => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has StackMin => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'] );
has StackMinEnabled => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has TotemSlots => ( is => 'rw', isa => 'Str', default => '1111', traits => ['Relevant'] );
has Unit => ( is => 'rw', isa => 'Str', default => 'player', traits => ['Relevant'] );
has UseActvtnOverlay => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'] );
has WpnEnchantType => ( is => 'rw', isa => 'Str', default => 'MainHandSlot', traits => ['Relevant'] );
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
    
    # add format if ShowTimerText is set
    if( $self->ShowTimerText ) {
        $self->SettingsPerView( WoWUI::Module::TellMeWhen::RawLua->new(
            luastr => "icon = { Texts = { [2] = '[Duration:TMWFormatDuration]' } }",
        ) );
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
                    my $cs = WoWUI::Module::TellMeWhen::Conditions->instance;
                    my $cname = $cs->nextanon;
                    $c = WoWUI::Module::TellMeWhen::Condition->new(
                        tag => $cname,
                        Name => $cname,
                        %$condition
                    );
                    WoWUI::Module::TellMeWhen::Conditions->instance->set( $cname, $c );
                }
                elsif( $condition =~ m/^icon:(.+)/ ) {
                    $c = WoWUI::Module::TellMeWhen::Condition::Icon->new( tag => $1, Icon => $1 );
                }
                else {
                    $c = WoWUI::Module::TellMeWhen::Conditions->instance->get( $condition );
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
sub _build_Name
{

    my $self = shift;
    $self->Name( $self->tag );

}

sub _build_SettingsPerView
{

    return WoWUI::Module::TellMeWhen::RawLua->new( luastr => '' );

}

# custom clone
sub clone
{

    my $self = shift;
    
    return $self->meta->clone_object(
        $self,
        Conditions => $self->Conditions->meta->clone_object( $self->Conditions ),
    );

}

sub augment_lua { '' }

sub select_extra
{

    my($self, $set) = @_;

    my $log = WoWUI::Util->log;
    
    # add icons that are part of conditions to the hidden set
    if( $self->cond_count ) {
        for my $cond( $self->Conditions->cond_values ) {
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
    for my $cond( $self->Conditions->cond_values ) {
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
    $self->Conditions->cond_clear;
    $self->Conditions->add_cond( @newc );
    
    # allow the subclass to do their own thing
    inner();

}

# keep require happy
1;

#
# EOF
