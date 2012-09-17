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

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
      
    my $config = $self->modconfig( $char );

    my $log = WoWUI::Util->logger;

    # Broker_Currency
    my @options;
    for my $gname( keys %{ $config->{groups} } ) {
        if( $f->match( $config->{groups}->{$gname}->{filter} ) ) {
            $log->trace("including group $gname");
            push @options, @{ $config->{groups}->{$gname}->{options} };
        }
    }

    $self->perchardata_set( options => \@options );
      
}

# keep require happy
1;

#
# EOF
