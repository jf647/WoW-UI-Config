package WoWUI::Module::BankStack;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->globalpc( 1 );
    
    return $self;
    
}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $config = $self->modconfig( $char );
    $self->globaldata_set( bindings => $config->{bankstack} );

}

# keep require happy
1;

#
# EOF
