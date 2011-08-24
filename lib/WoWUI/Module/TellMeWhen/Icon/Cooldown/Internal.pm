#
# $Id: Internal.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown';
has '+priority' => ( default => 2450 );
has '+Type' => ( default => 'icd' );
has '+ShowTimer' => ( default => 1 );
has '+ICDType' => ( relevant => 1 );
has [ qw|
    +IgnoreRunes +ManaCheck +OnlyEquipped
    +OnlyInBags +PBarOffs +RangeCheck
    +ShowPBar +CooldownType
| ] => ( relevant => 0 );
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
