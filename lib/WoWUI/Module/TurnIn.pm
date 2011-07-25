#
# $Id: TurnIn.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::TurnIn;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
augment data => \&augment_data;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'turnin', global => 1, perchar => 0 };
}

sub augment_data
{

  my $self = shift;

  my $config = $self->config;
  my $options = WoWUI::Machine->instance->modoption_get($self->name);

  # TurnIn
  my $data;
  if( exists $options->{startquest} ) {
    $data = $options;
  }
  else {
    $data = { startquest => 0, finishquest => 0 };
  }
  $data->{npcs} = $config->{npcs};

  return $data;

}

# keep require happy
1;

#
# EOF