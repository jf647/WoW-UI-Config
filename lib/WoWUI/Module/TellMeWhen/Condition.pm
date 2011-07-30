#
# $Id: Condition.pm 5015 2011-05-30 11:39:08Z james $
#

package WoWUI::Module::TellMeWhen::Condition;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has tag => ( is => 'rw', isa => 'Str', required => 1 );
has AndOr => ( is => 'rw', isa => 'Str', default => 'AND', traits => ['Relevant'], relevant => 1 );
has Type => ( is => 'rw', isa => 'Str', default => 'HEALTH', traits => ['Relevant'], relevant => 1 );
has Icon => ( is => 'rw', isa => 'Str', default => "", traits => ['Relevant'], relevant => 1 );
has Operator => ( is => 'rw', isa => 'Str', default => '==', traits => ['Relevant'], relevant => 1 );
has Level => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'], relevant => 1 );
has Unit => ( is => 'rw', isa => 'Str', default => 'player', traits => ['Relevant'], relevant => 1 );
has Name => ( is => 'rw', isa => 'Str', default => "", traits => ['Relevant'], relevant => 1 );
has [ qw|PrtsBefore PrtsAfter| ] => ( is => 'rw', isa => 'Int', default => 0, traits => ['Relevant'], relevant => 1 );
has Checked => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has Runes => (
    is => 'rw',
    isa => 'WoWUI::Module::TellMeWhen::Condition::Runes',
    default => sub { WoWUI::Module::TellMeWhen::Condition::Runes->new },
    traits => ['Relevant'],
    relevant => 1,
);
__PACKAGE__->meta->make_immutable;

# constructor
sub BUILDARGS
{

    my $class = shift;
    my %a = @_;
    if( exists $a{Runes} ) {
        $a{Runes} = WoWUI::Module::TellMeWhen::Condition::Runes->new(
            runes => $a{Runes},
        );
    }
    return \%a;

}

# constructor
sub BUILD
{

    my $self = shift;
    my $ccfg = shift;
    
    if( 'SPELLCD' eq $self->Type && exists $ccfg->{spellid} ) {
        $self->Name( $ccfg->{spellid} );
    }

}

# the Dumpable role requires that we provide this
sub augment_lua { "" }

# keep require happy
1;

#
# EOF
