#
# $Id$
#

package WoWUI::ModConfig;
use Moose::Role;

has _modconfig => (
    is      => 'bare',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        modconfig_set     => 'set',
        modconfig_get     => 'get',
        modconfig_exists  => 'exists',
        modconfigs_list   => 'keys',
        modconfigs_values => 'values',
    },
);

use Hash::Merge::Simple 'merge';

sub set_modconfig
{

    my $self = shift;
    my $cfg  = shift;

    for my $key ( keys %{ $cfg->{modconfig} } ) {
        if ( $self->modconfig_exists($key) ) {
            $self->modconfig_set(
                merge( $self->modconfig_get($key), $cfg->{modconfig}->{$key} )
            );
        }
        else {
            $self->modconfig_set( $key, $cfg->{modconfig}->{$key} );
        }
    }

    return;

}

# keep require happy
1;

#
# EOF
