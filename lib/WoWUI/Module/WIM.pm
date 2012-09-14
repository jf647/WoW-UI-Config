#
# $Id: WIM.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::WIM;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
with 'WoWUI::NoGlobalData';
CLASS->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD {

    my $self = shift;

    $self->global(1);

    return $self;

}

# keep require happy
1;

#
# EOF
