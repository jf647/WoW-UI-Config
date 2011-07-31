#
# $Id: Bagnon.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Bagnon;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

# class attributes
CLASS->perchar( 1 );

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $o = $self->modoptions( $char );
  
  # money frame defaults to on
  my $moneyframe = 1;
  # turn off the money frame for master machines on chars that have broker_currency enabled
  if( WoWUI::Util::Filter::matches( $char->flags_get('common'), $char, { addons => [ 'Broker_Currency' ], include => [ 'machine:type:master' ] } ) ) {
    $moneyframe = 0;
  }

  return { realm => $char->realm->name, char => $char->name, scale => $o->{scale}, moneyframe => $moneyframe };

}

# keep require happy
1;

#
# EOF
