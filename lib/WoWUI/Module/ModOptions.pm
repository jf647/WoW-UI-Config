#
# $Id$
#

package WoWUI::Module::ModOptions;
use Moose::Role;

has modoptions => (
  is => 'bare',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    modoption_set => 'set',
    modoption_get => 'get',
    modoption_exists => 'exists',
    modoptions_list => 'keys',
    modoptions_values => 'values',
  },
);

# keep require happy
1;

#
# EOF
