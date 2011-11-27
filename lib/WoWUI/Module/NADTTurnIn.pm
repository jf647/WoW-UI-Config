#
# $Id: TurnIn.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::NADTTurnIn;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->global( 1 );
    $self->perchar( 1 );
    
    return $self;
    
}

sub augment_global
{

    my $self = shift;

    $self->globaldata_set( npcs => $self->modconfig->{npcs} );

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $o = $self->modoptions;
    unless( exists $o->{ignore_perchar_modoptions} ) {
        $o = $self->modoptions( $char );
    }

    for my $key( qw|startquest finishquest| ) {
        if( exists $o->{$key} ) {
            $self->perchardata_set( $key => $o->{$key} );
        }
        else {
            $self->perchardata_set( $key => 0 );
        }
    }

}

# keep require happy
1;

#
# EOF
