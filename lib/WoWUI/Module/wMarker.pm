#
# $Id: wMarker.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::wMarker;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

# class attributes
__PACKAGE__->name( 'wmarker' );
__PACKAGE__->perchar( 1 );

# keep require happy
1;

#
# EOF
