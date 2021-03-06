#
# $Id: Totem.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Totem;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
has '+priority' => ( default => 5050 );
has '+Type' => ( default => 'totem' );
has '+ShowWhen' => ( relevant => 1 );
has '+TotemSlots' => ( relevant => 1 );
with 'WoWUI::Module::TellMeWhen::Icon::SpellItemName';
with 'WoWUI::Module::TellMeWhen::Icon::Present';
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
