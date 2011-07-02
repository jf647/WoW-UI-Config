#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machines;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has 'file' => ( is => 'rw', isa => 'Str' );
has 'cfg' => ( is => 'rw', isa => 'HashRef' );
has machines => (
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

use Carp 'croak';

use WoWUI::Util qw|log expand_path|;

sub BUILD
{

  my $self = shift;
  
  return $self;
  
}   

# keep require happy
1;

#
# EOF
