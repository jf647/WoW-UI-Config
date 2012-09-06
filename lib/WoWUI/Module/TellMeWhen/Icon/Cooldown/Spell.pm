#
# $Id: Spell.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell;
use Moose;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown';
has '+priority' => ( default => 2350 );
has '+CooldownType' => ( default => 'spell' );
with 'WoWUI::Module::TellMeWhen::Icon::SpellItemName';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Off;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Offensive';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Off::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Off';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Off::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Off';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Def;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Defensive';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Def::ShortCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Def';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::ShortCD';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Def::LongCD;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Spell::Def';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::LongCD';
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
