package WoWUI::Module::Prat;
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
    $self->globalpc( 1 );
    
    return $self;

}

sub augment_global
{

    my $self = shift;

    my $config = $self->modconfig;

    my $prat = {
        frame => $config->{frame},
        editbox => $config->{editbox},
        fading => $config->{fading},
        popup => $config->{popup},
        buttons => $config->{buttons},
        modules => $config->{modules},
    };
    
    $self->globaldata_set( prat => $prat );

}

sub augment_globalpc
{

    return 1;
    
}