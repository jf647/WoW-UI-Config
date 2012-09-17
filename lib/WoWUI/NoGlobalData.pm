package WoWUI::NoGlobalData;
use Moose::Role;

sub augment_global
{

    my $self = shift;
    $self->globaldata_set( $self->name => 1 );

    return;

}

1;
