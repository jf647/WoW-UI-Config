#
# $Id: Config.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Config;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has 'dirs' => ( is => 'rw', ias => 'ArrayRef[Str]' );
has 'file' => ( is => 'rw', isa => 'Str' );
has 'cfg' => ( is => 'rw', isa => 'HashRef' );

use Carp 'croak';

use WoWUI::Util qw|load_layered|;

# constructor
sub BUILD
{  
  
    my $self = shift;
    $self->cfg( load_layered( $self->file, @{ $self->dirs } ) );

}

# keep require happy
1;

#
# EOF
