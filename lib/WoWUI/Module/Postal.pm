#
# $Id: Postal.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Postal;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'postal' );
__PACKAGE__->global( 1 );

sub augment_data
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    my $data;

    for my $realm( $self->player->realms ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars ) {
            $log->debug("processing character ", $char->name);
            $data->{postal}->{$realm->name}->{$char} = {
                name => $char->name,
                faction => $char->faction,
                class => $char->class_ns,
                level => $char->level,
            };
        }
    }
    
    return $data;

}

# keep require happy
1;

#
# EOF
