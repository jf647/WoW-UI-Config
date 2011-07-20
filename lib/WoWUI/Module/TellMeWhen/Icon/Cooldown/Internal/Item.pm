#
# $Id: Item.pm 5032 2011-06-07 08:01:39Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal::Item;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Cooldown::Internal';
has '+CooldownType' => ( default => 'item' );
#has '+ICDDuration' => ( default => 45 );
__PACKAGE__->meta->make_immutable;

# keep require happy
1;

#
# EOF
