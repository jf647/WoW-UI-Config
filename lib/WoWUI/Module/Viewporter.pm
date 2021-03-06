#
# $Id: Viewporter.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Viewporter;
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
    
    $self->perchar( 1 );
    
    return $self;
    
}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $o = $self->modoptions( $char );

    # Viewporter
    for my $side( qw|top bottom left right| ) {
        if( exists $o->{$side} ) {
            $self->perchardata_set( $side => $o->{$side} );
        }
        else {
            $self->perchardata_set( $side => 0 );
        }
    }

}

# keep require happy
1;

#
# EOF
