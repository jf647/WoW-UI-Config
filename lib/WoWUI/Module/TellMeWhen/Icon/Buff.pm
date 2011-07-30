#
# $Id: Buff.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Buff;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Aura';
has '+priority' => ( default => 3050 );
has '+BuffOrDebuff' => ( default => 'HELPFUL' );
__PACKAGE__->meta->make_immutable;

# keep require happy
1;

#
# EOF
