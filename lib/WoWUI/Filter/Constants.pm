#
# $Id: Constants.pm 4992 2011-05-23 15:03:57Z james $
#

package WoWUI::Filter::Constants;
use base 'Exporter';

# constants
use constant {
    F_C0    => 0x001,
    F_C1    => 0x002,
    F_C2    => 0x004,
    F_CALL  => 0x00F,
    F_REALM => 0x010,
    F_MACH  => 0x100,
    F_ALL   => 0xFFF,
};
our @EXPORT = qw|F_C0 F_C1 F_C2 F_CALL F_REALM F_MACH F_ALL|;

# keep require happy
1;

#
# EOF
