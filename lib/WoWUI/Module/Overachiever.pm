#
# $Id: Overachiever.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Overachiever;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'overachiever' );
__PACKAGE__->global( 1 );

sub augment_data
{

  my $self = shift;

  my $config = $self->config;
  my $o = $self->modoptions;

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
