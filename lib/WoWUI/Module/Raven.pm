#
# $Id: Raven.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Raven;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'raven' );
__PACKAGE__->global( 1 );

sub augment_data
{

    my $self = shift;

    my $config = $self->config;
    my $o = $self->modoptions;

    my $log = WoWUI::Util->log;

    my $data = { raven => $o };

    # per-char settings
    for my $realm( $self->player->realms ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars ) {

            if( exists $config->{perchar_criteria} ) {
                next unless( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{perchar_criteria} ) );
            }

            $data->{raven}->{realms}->{$realm->name}->{$char->name} = {};

            if( exists $config->{icbuffs}->{$char->class} ) {
                $data->{raven}->{realms}->{$realm->name}->{$char->name}->{icbuffs} =  $config->{icbuffs}->{$char->class};
            }
            
        }
    }

    return $data;

}

# keep require happy
1;

#
# EOF
