#
# $Id: Constants.pm 4992 2011-05-23 15:03:57Z james $
#

package WoWUI::Filter::Constants;
use base 'Exporter';

use strict;
use warnings;

use ReadOnly

  # constants
  ReadOnly my $F_C0 => 0x01;
ReadOnly my $F_C1       => 0x02,
  ReadOnly my $F_C2     => 0x04,
  ReadOnly my $F_CALL   => 0x0F,
  ReadOnly my $F_REALM  => 0x10,
  ReadOnly my $F_MACH   => 0x20,
  ReadOnly my $F_PLAYER => 0x40,
  ReadOnly my $F_MPR    => 0xF0,
  ReadOnly my $F_ALL    => 0xFF,

  # exports
  our @EXPORT = qw|
  $F_C0 $F_C1 $F_C2 $F_CALL
  $F_REALM $F_MACH $F_PLAYER $F_MPR
  $F_ALL
  |;

# keep require happy
1;

#
# EOF
