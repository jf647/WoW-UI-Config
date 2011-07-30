#
# $Id: Aura.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Aura;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
has stacks => ( is => 'ro', isa => 'HashRef' );
has duration => ( is => 'ro', isa => 'HashRef' );
has '+Type' => ( default => 'buff' );
has '+BuffOrDebuff' => ( relevant => 1, default => 'HELPFUL' );
has '+ShowWhen' => ( relevant => 1 );
has '+Alpha' => ( default => 0.5 );
has [ qw|
    +OnlyMine +PBarOffs +ShowPBar
    +StackMax +StackMaxEnabled +StackMin
    +StackMinEnabled +Unit +Sort +SortAsc +SortDesc
| ] => ( relevant => 1 );
with 'WoWUI::Module::TellMeWhen::Icon::SpellName';
with 'WoWUI::Module::TellMeWhen::Icon::Present';
__PACKAGE__->meta->make_immutable;

# constructor
sub BUILD
{

    my $self = shift;

    # stacks
    if( $self->stacks ) {
        if( exists $self->stacks->{min} ) {
            $self->StackMinEnabled( 1 );
            $self->StackMin( $self->stacks->{min} );
        }
        if( exists $self->stacks->{max} ) {
            $self->StackMaxEnabled( 1 );
            $self->StackMax( $self->stacks->{max} );
        }
    }

    # durations
    if( $self->duration ) {
        if( exists $self->duration->{min} ) {
            $self->DurationMinEnabled( 1 );
            $self->DurationMin( $self->duration->{min} );
        }
        if( exists $self->duration->{max} ) {
            $self->DurationMaxEnabled( 1 );
            $self->DurationMax( $self->duration->{max} );
        }
    }
    
    return $self;

}

# keep require happy
1;

#
# EOF
