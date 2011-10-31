#
# $Id: Item.pm 5032 2011-06-07 08:01:39Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Item;
use Moose;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
has '+priority' => ( default => 2050 );
has '+Type' => ( default => 'item' );
has [ qw|
    +OnlyEquipped +OnlyInBags
    +OnlySeen +RangeCheck +EnableStacks
    +StackMinEnabled +StackMaxEnabled
    +StackMin +StackMax
| ] => ( relevant => 1 );
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::Off;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Offensive';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::Off::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item::Off';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::Off::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item::Off';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::Def;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Defensive';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::Def::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item::Def';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Item::Def::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Item::Def';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
