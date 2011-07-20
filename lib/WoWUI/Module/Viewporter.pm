#
# $Id: Viewporter.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Viewporter;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'viewporter' );
__PACKAGE__->perchar( 1 );

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $config = $self->config;
  my $o = $self->modoptions( $char );

  my $chardata = { realm => $char->realm->name, char => $char->name };

  # Viewporter
  if( exists $o->{bottom} ) {
    $chardata->{bottom} = $o->{bottom};
  }
  else {
    $chardata->{bottom} = 0;
  }

  return $chardata;

}

# keep require happy
1;

#
# EOF
