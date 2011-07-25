#
# $Id: Postal.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Postal;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Basic';
augment data => \&augment_data;
__PACKAGE__->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'postal', global => 1, perchar => 0 };
}

sub augment_data
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    my $data;

    for my $realm( WoWUI::Profile->instance->realms_values ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars_values ) {
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