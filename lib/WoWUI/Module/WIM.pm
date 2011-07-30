#
# $Id: WIM.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::WIM;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'wim' );
__PACKAGE__->global( 1 );

# keep require happy
1;

#
# EOF
