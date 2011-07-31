#
# $Id: TurnIn.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::TurnIn;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->global( 1 );
    
    return $self;
    
}

sub augment_data
{

  my $self = shift;

  my $config = $self->config;
  my $options = $self->modoptions;

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
