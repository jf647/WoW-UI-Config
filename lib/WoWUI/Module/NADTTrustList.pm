package WoWUI::Module::NADTTrustList;
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
use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->perchar( 1 );
    
    return $self;
    
}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $o = $self->modoptions( $char );
    
    my $trust = $o->{trust} || [];

    $self->perchardata_set( trust => $trust );

}

# keep require happy
1;

#
# EOF
