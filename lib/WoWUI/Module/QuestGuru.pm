#
# $Id: QuestGuru.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::QuestGuru;
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
    $self->perchar( 1 );
    
    return $self;
    
}

sub augment_data
{

  my $self = shift;

  my $config = $self->config;
  my $o = $self->modoptions;

  my $data;

  # Questguru Party Announce
  if( exists $o->{announce} ) {
    $data->{announce} = $o->{announce};
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
