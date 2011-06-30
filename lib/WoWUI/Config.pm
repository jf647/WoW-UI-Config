#
# $Id: Config.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Config;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has 'file' => ( is => 'rw', isa => 'Str' );
has 'cfg' => ( is => 'rw', isa => 'HashRef' );
# causes problems - build is never called with 0.27 of MooseX::Singleton
#__PACKAGE__->meta->make_immutable;

use Carp 'croak';

use WoWUI::Util qw|load_file|;

# constructor
sub BUILD
{  
  
    my $self = shift;
    $self->cfg( load_file( $self->file ) );

}

# keep require happy
1;

#
# EOF
