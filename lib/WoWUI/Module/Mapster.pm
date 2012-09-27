package WoWUI::Module::Mapster;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

# constructor
sub BUILD
{

    my $self = shift;

    $self->global(1);
    $self->globalpc(1);

    return $self;

}

sub augment_global
{

    my $self = shift;

    my $config = $self->modconfig;

    $self->globaldata_set( mapster => $config->{mapster} );

    return;

}

sub augment_globalpc { return 1 }

1;
