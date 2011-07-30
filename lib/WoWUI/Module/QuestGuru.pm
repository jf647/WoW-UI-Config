#
# $Id: QuestGuru.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::QuestGuru;
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
__PACKAGE__->name( 'questguru' );
__PACKAGE__->global( 1 );
__PACKAGE__->perchar( 1 );

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
