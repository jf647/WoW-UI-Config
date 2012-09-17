package WoWUI::NoPercharData;
use Moose::Role;

sub augment_perchar
{

    my $self = shift;
    $self->perchardata_set( $self->name => 1 );

    return;

}

1;
