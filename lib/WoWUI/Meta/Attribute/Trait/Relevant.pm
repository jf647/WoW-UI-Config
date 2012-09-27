package WoWUI::Meta::Attribute::Trait::Relevant;
use Moose::Role;

use strict;
use warnings;

# set up class
has relevant => ( is => 'rw', isa => 'Bool', default => 0 );

1;
