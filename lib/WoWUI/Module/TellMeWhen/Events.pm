#
# $Id: Events.pm 5008 2011-05-29 09:35:09Z james $
#

package WoWUI::Module::TellMeWhen::Events;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

use WoWUI::Module::TellMeWhen::Event;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has [ qw|OnShow OnHide OnStart OnFinish| ] => (
    is => 'rw',
    isa => 'WoWUI::Module::TellMeWhen::Event',
    traits => ['Relevant'],
    relevant => 1,
    default => sub { WoWUI::Module::TellMeWhen::Event->new },
);
__PACKAGE__->meta->make_immutable;

# the Dumpable role requires that we provide this
sub augment_lua { "" }

# keep require happy
1;

#
# EOF
