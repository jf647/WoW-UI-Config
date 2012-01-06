package WoWUI::Module::TipTac;
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
    
    $self->global( 1 );
    
    return $self;

}

sub augment_global
{

    my $self = shift;

    my $config = $self->modconfig;

    my $tiptac = {
        anchor => $config->{anchor},
        fontsize => $config->{fontsize},
        barfontsize => $config->{barfontsize},
        scale => $config->{scale},
        fadetime => $config->{fadetime},
        prefadetime => $config->{prefadetime},
    };
    
    $self->globaldata_set( tiptac => $tiptac );

}
