#
# $Id: Debuff.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Debuff;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon::Aura';
has '+priority' => ( default => 3150 );
has '+BuffOrDebuff' => ( default => 'HARMFUL' );
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
