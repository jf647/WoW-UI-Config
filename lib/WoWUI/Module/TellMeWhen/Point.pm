#
# $Id: Point.pm 5015 2011-05-30 11:39:08Z james $
#

package WoWUI::Module::TellMeWhen::Point;
use Moose;

use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has [ qw|point relativePoint| ] => ( is => 'rw', isa => 'Str', default => 'CENTER', traits => ['Relevant'], relevant => 1 );
has [ qw|relativeTo| ] => ( is => 'rw', isa => 'Str', default => 'UIParent', traits => ['Relevant'], relevant => 1 );
has x => ( is => 'rw', isa => 'Num', default => 0, traits => ['Relevant'], relevant => 1 );
has y => ( is => 'rw', isa => 'Num', default => 0, traits => ['Number','Relevant'], handles => { y_down => 'sub' }, relevant => 1 );
__PACKAGE__->meta->make_immutable;

# the Dumpable role requires that we provide this
sub augment_lua { "" }

# keep require happy
1;

#
# EOF
