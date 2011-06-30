#
# $Id: SexyMap.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::SexyMap;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Basic';
__PACKAGE__->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'sexymap', global => 1, perchar => 0 };
}

# keep require happy
1;

#
# EOF
