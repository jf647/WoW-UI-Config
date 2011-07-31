#
# $Id: Event.pm 5029 2011-06-06 07:01:30Z james $
#

package WoWUI::Module::TellMeWhen::Event;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has Sound => ( is => 'rw', isa => 'Str', default => 'None', traits => ['Relevant'], relevant => 1 );
has Sticky => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has Icon => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has Size => ( is => 'rw', isa => 'Num', default => 0, traits => ['Relevant'], relevant => 1 );
has [ qw|Text Channel Location| ] => ( is => 'rw', isa => 'Str', default => '', traits => ['Relevant'], relevant => 1 );
has [ qw|r g b| ] => ( is => 'rw', isa => 'Num', default => 1, traits => ['Relevant'], relevant => 1 );
CLASS->meta->make_immutable;

# the Dumpable role requires that we provide this
sub augment_lua { "" }

# keep require happy
1;

#
# EOF
