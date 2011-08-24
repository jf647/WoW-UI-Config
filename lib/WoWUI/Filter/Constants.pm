#
# $Id: Constants.pm 4992 2011-05-23 15:03:57Z james $
#

package WoWUI::Filter::Constants;
use base 'Exporter';

# constants
use constant {
    F_C0     => 0x01,
    F_C1     => 0x02,
    F_C2     => 0x04,
    F_CALL   => 0x0F,
    F_REALM  => 0x10,
    F_MACH   => 0x20,
    F_PLAYER => 0x40,
    F_MPR    => 0xF0,
    F_ALL    => 0xFF,
};
our @EXPORT = qw|
    F_C0 F_C1 F_C2 F_CALL
    F_REALM F_MACH F_PLAYER F_MPR
    F_ALL
|;

# keep require happy
1;

#
# EOF
