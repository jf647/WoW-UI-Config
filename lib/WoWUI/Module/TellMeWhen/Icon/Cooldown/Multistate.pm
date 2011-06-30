#
# $Id: Multistate.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Multistate;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown';
has '+priority' => ( default => 2250 );
has '+CooldownType' => ( default => 'multistate' );
with 'WoWUI::Module::TellMeWhen::Icon::SpellName';
__PACKAGE__->meta->make_immutable;

# keep require happy
1;

#
# EOF
