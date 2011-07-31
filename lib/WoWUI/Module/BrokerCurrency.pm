#
# $Id: BrokerCurrency.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::BrokerCurrency;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

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
