#
# $Id: Config.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Config;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has dirs => ( is => 'rw', isa => 'ArrayRef[Str]' );
has file => ( is => 'rw', isa => 'Str' );
has cfg => ( is => 'rw', isa => 'HashRef' );
has initialized => ( is => 'rw', isa => 'Bool', default => 0 );

use Carp 'croak';

use WoWUI::Util qw|load_layered|;

# constructor
sub BUILD
{  
  
    my $self = shift;
    $DB::single = 1;
    $self->cfg( load_layered( $self->file, @{ $self->dirs } ) );
    $self->initialized( 1 );

}

# keep require happy
1;

#
# EOF
