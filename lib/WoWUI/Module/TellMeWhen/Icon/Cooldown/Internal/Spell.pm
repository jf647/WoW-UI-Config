#
# $Id: Spell.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal::Spell;
use Moose;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal';
has '+CooldownType' => ( default => 'spell' );
with 'WoWUI::Module::TellMeWhen::Icon::SpellName';
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
