#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machine;
use Moose;

use namespace::autoclean;

# set up class
has 'name' => ( is => 'rw', isa => 'Str', required => 1 );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has 'options' => ( is => 'rw', isa => 'HashRef' );
has output => ( is => 'rw', isa => 'Path::Class::File' );
has 'modoptions' => (
  is => 'rw',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    modoption_set => 'set',
    modoption_get => 'get',
    modoptions_list => 'keys',
    modoptions_values => 'values',
  },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

# keep require happy
1;

#
# EOF
