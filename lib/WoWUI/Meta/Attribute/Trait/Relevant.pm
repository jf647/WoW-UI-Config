#
# $Id: Relevant.pm 5001 2011-05-27 12:13:58Z james $
#

package WoWUI::Meta::Attribute::Trait::Relevant;
use Moose::Role;

# set up class
has relevant => ( is => 'rw', isa  => 'Bool', default => 0 );

# register the new metadata implementation with Moose
package Moose::Meta::Attribute::Custom::Trait::Relevant;
sub register_implementation { 'WoWUI::Meta::Attribute::Trait::Relevant' }  

# keep require happy
1;

#
# EOF
