#
# $Id: Overachiever.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Overachiever;
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
    return { @_, name => 'overachiever', global => 1, perchar => 0 };
}

sub augment_data
{

  my $self = shift;

  my $config = $self->config;
  # XXX
  my $o = WoWUI::Machine->instance->modoption_get($self->name);

  my $data = {};
  
  for my $achievement( @{ $config->{achievements} } ) {
      if( exists $o->{$achievement} ) {
          $data->{$achievement} = 1;
      }
      else {
          $data->{$achievement} = 0;
      }
  }
  
  return $data;

}

# keep require happy
1;

#
# EOF
