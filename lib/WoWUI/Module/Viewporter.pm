#
# $Id: Viewporter.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Viewporter;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->perchar( 1 );
    
    return $self;
    
}

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
