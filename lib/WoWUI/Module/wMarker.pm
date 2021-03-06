#
# $Id: wMarker.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::wMarker;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
with 'WoWUI::NoPercharData';
CLASS->meta->make_immutable;

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->perchar( 1 );
    
    return $self;
    
}

# keep require happy
1;

#
# EOF
