#
# $Id: Constants.pm 4992 2011-05-23 15:03:57Z james $
#

package WoWUI::Filter::Constants;
use base 'Exporter';

# constants
use constant {
    F_C0     => 0x0001,
    F_C1     => 0x0002,
    F_C2     => 0x0004,
    F_CALL   => 0x000F,
    F_REALM  => 0x0010,
    F_MACH   => 0x0100,
    F_PLAYER => 0x1000,
    F_ALL    => 0xFFFF,
};
our @EXPORT = qw|F_C0 F_C1 F_C2 F_CALL F_REALM F_MACH F_PLAYER F_ALL|;

# keep require happy
1;

#
# EOF
