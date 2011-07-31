#
# $Id: FreeRefills.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::FreeRefills;
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
CLASS->global( 1 );

sub augment_data
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    my $config = $self->config;

    my $data;
  
    for my $realm( $self->player->realms ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars ) {
            if( exists $config->{perchar_criteria} ) {
                next unless( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{perchar_criteria} ) );
            }
            $log->debug("processing character ", $char->name);
            my %items;
            for my $fr( keys %{ $config->{freerefills} } ) {
                my $frdata = $config->{freerefills}->{$fr};
                if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $frdata ) ) {
                    if( exists $items{$frdata->{itemid}} ) {
                        croak "$fr has been picked twice for ", $realm->name, "/", $char->name;
                    }
                    $items{$frdata->{itemid}} = clone $frdata;
                    unless( exists $frdata->{name} ) {
                        $items{$frdata->{itemid}}->{name} = $fr;
                    }
                }
            }
            if( %items ) {
                $data->{freerefills}->{$realm->name}->{$char->name} = [ values %items ];
            }
        }
    }

    return $data;

}

# keep require happy
1;

#
# EOF
