#
# $Id: TurnIn.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::TurnIn;
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
    
    return $self;
    
}

sub augment_global
{

    my $self = shift;

    my $o = $self->modoptions;

    for my $key( qw|startquest finishquest| ) {
        if( exists $o->{$key} ) {
            $self->globaldata_set( $key => $o->{$key} );
        }
        else {
            $self->globaldata_set( $key => 0 );
        }
    }

    $self->globaldata_set( npcs => $self->modconfig->{npcs} );

}

# keep require happy
1;

#
# EOF
