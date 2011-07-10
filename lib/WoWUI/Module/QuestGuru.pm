#
# $Id: QuestGuru.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::QuestGuru;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
augment data => \&augment_data;
augment chardata => \&augment_chardata;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'questguru', global => 1, perchar => 1 };
}

sub augment_data
{

  my $self = shift;

  my $config = $self->config;
  # XXX
  my $options = WoWUI::Machine->instance->modoption_get($self->name);

  my $data;

  # Questguru Party Announce
  if( exists $options->{announce} ) {
    $data->{announce} = $options->{announce};
  }
  else {
    $data->{announce} = 0;
  }

  return $data;

}

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  return { realm => $char->realm->name, char => $char->name };

}

# keep require happy
1;

#
# EOF
