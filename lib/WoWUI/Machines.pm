
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machines;
use MooseX::Singleton;
use MooseX::StrictConstructor;

use Carp 'croak';
use namespace::autoclean;

# set up class
has file => ( is => 'rw', isa => 'Str' );
has cfg => ( is => 'rw', isa => 'HashRef' );
has machines => (
  is => 'bare',
  isa => 'HashRef[WoWUI::Machine]',
  default => sub { {} },
  traits => ['Hash'],
  handles => {
    machine_get => 'get',
    machine_set => 'set',
    machine_names => 'keys',
    machine_exists => 'exists',
    machines => 'values',
  },
);
before machine_get => sub {
    my $self = shift;
    my $machname = shift;
    return if( $self->machine_exists( $machname ) );
    unless( exists $self->cfg->{$machname} ) {
        croak "no such machine '$machname'";
    }
    my $machine = WoWUI::Machine->new( $machname, $self->cfg->{$machname}->{players} );
    $self->machine_set( $machname, $machine );
};

use WoWUI::Util qw|log expand_path load_file|;
use WoWUI::Machine;

# constructor
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
