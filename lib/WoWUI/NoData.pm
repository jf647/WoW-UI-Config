#
# $Id$
#

package WoWUI::NoGlobalData;
use Moose::Role;

sub augment_global
{

    my $self = shift;
    $self->globaldata_set( $self->name => 1 );

}

package WoWUI::NoPercharData;
use Moose::Role;

sub augment_perchar
{

    my $self = shift;
    $self->perchardata_set( $self->name => 1 );

}

# keep require happy
1;

#
# EOF
