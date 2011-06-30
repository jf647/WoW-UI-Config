#
# $Id: Internal.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown';
has '+priority' => ( default => 2450 );
has '+Type' => ( default => 'icd' );
has '+ShowTimer' => ( default => 1 );
has '+ICDType' => ( relevant => 1 );
has '+ICDDuration' => ( relevant => 1, required => 1 );
has [ qw|
    +IgnoreRunes +ManaCheck +OnlyEquipped
    +OnlyInBags +PBarOffs +RangeCheck
    +ShowPBar +CooldownType
| ] => ( relevant => 0 );
__PACKAGE__->meta->make_immutable;

# constructor
sub BUILD
{

    my $self = shift;
    my $icfg = shift;

    # usable / unusable
    if( exists $icfg->{unusable} ) {
        $self->ShowWhen( 'unalpha' );
        $self->UnAlpha( 0.5 );
    }
    elsif( exists $icfg->{always} ) {
        $self->ShowWhen( 'always' );
        $self->UnAlpha( 0.5 );
    }
    
    return $self;

}

# keep require happy
1;

#
# EOF
