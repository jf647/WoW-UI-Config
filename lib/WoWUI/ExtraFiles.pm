
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::ExtraFiles;
use MooseX::Singleton;
use MooseX::StrictConstructor;

use strict;
use warnings;
use namespace::autoclean;

# set up class
has files => (
    is      => 'bare',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        add     => 'set',
        files   => 'keys',
        zipfile => 'get',
        reset   => 'clear',
    },
);

# keep require happy
1;

#
# EOF
