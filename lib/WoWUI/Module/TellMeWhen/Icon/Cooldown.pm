#
# $Id: Cooldown.pm 5032 2011-06-07 08:01:39Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
with 'WoWUI::Module::TellMeWhen::Icon::Usable';
has '+priority' => ( default => 2050 );
has '+Type' => ( default => 'cooldown' );
has '+CooldownCheck' => ( default => 1 );
has '+CooldownType' => ( relevant => 1, default => 'spell' );
has '+ShowWhen' => ( relevant => 1 );
has '+Alpha' => ( default => 0.5 );
has [ qw|
    +IgnoreRunes +ManaCheck +OnlyEquipped
    +OnlyInBags +PBarOffs +RangeCheck
    +ShowPBar
| ] => ( relevant => 1 );
__PACKAGE__->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::ShortCD;
use Moose;

use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
__PACKAGE__->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::LongCD;
use Moose;

use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
__PACKAGE__->meta->make_immutable;

# keep require happy
1;

#
# EOF
