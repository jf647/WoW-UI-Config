#
# $Id$
#

package WoWUI::ModOptions;
use Moose::Role;

has _modoptions => (
    is => 'bare',
    isa => 'HashRef',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        modoption_set => 'set',
        modoption_get => 'get',
        modoption_exists => 'exists',
        modoptions_list => 'keys',
        modoptions_values => 'values',
    },
);

use Hash::Merge::Simple 'merge';

sub modoptions_set
{

    my $self = shift;
    my $cfg = shift;

    for my $key( keys %{ $cfg->{modoptions} } ) {
        if( $self->modoption_exists( $key ) ) {
            $self->modoption_set( merge( $self->modoption_get( $key ), $cfg->{modoptions}->{$key} ) );
        }
        else {
            $self->modoption_set( $key, $cfg->{modoptions}->{$key} );
        }
    }

}

# keep require happy
1;

#
# EOF
