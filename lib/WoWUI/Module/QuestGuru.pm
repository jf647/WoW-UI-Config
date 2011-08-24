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
with 'WoWUI::NoPercharData';
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

sub augment_global
{

  my $self = shift;

  my $o = $self->modoptions;

  # Questguru Party Announce
  if( exists $o->{announce} ) {
    $self->globaldata_set( announce => 1 );
  }
  else {
    $self->globaldata_set( announce => 0 );
  }

}

# keep require happy
1;

#
# EOF
