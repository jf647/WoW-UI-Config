#
# $Id: BrokerCurrency.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::BrokerCurrency;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
augment chardata => \&augment_chardata;
__PACKAGE__->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'brokercurrency' );
__PACKAGE__->perchar( 1 );

sub augment_chardata
{

  my $self = shift;
  my $char = shift;
  
  my $config = $self->config;

  my $chardata = { realm => $char->realm->name, char => $char->name };

  my $log = WoWUI::Util->log;

  # Broker_Currency
  for my $currency( keys %{ $config->{currencies} } ) {
    if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{currencies}->{$currency} ) ) {
      $log->trace("including currency $currency");
      $chardata->{$currency} = 1;
    }
  }
  
  return $chardata;

}

# keep require happy
1;

#
# EOF
