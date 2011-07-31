#
# $Id: Item.pm 5032 2011-06-07 08:01:39Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item;
use Moose;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown';
has '+priority' => ( default => 2050 );
has '+CooldownType' => ( default => 'item' );
has [ qw|
    +HideUnequipped +OnlyEquipped +OnlyInBags
    +OnlySeen
| ] => ( relevant => 1 );
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Off;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Offensive';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Off::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Off';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Off::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Off';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Def;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Defensive';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Def::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Def';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Def::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Item::Def';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
