#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machines;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has file => ( is => 'rw', isa => 'Str' );
has cfg => ( is => 'rw', isa => 'HashRef' );
has machines => (
  is => 'bare',
  isa => 'HashRef[WoWUI::Machine|HashRef]',
  default => sub { {} },
  traits => ['Hash'],
  handles => {
    machine_get => 'get',
    machine_set => 'set',
  },
);

use Carp 'croak';

use WoWUI::Util qw|log expand_path load_file|;

sub BUILDARGS
{

  my $class = shift;
  return { file => shift };

}

sub BUILD
{

  my $self = shift;

  $self->cfg( load_file( expand_path( $self->file ) ) );
  
  return $self;
  
}   

# keep require happy
1;

#
# EOF
