#
# $Id: Config.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Config;
use MooseX::Singleton;
use MooseX::StrictConstructor;

use namespace::autoclean;
use strict;
use warnings;

# set up class
has dirs        => ( is => 'rw', isa => 'ArrayRef[Str]' );
has file        => ( is => 'rw', isa => 'Str' );
has cfg         => ( is => 'rw', isa => 'HashRef' );
has initialized => ( is => 'rw', isa => 'Bool', default => 0 );

use Carp 'croak';

use WoWUI::Util qw|load_layered|;

# constructor
sub BUILD
{

    my $self = shift;
    $self->cfg( load_layered( $self->file, @{ $self->dirs } ) );
    $self->initialized(1);

    return;

}

# keep require happy
1;

#
# EOF
