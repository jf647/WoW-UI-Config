#
# $Id: Auctionator.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Auctionator;
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

    $self->perchar( 1 );
    
    return $self;

}

sub augment_perchar
{

    my $self = shift;
    $self->perchardata_set( auctionator => 1 );
    
}

# keep require happy
1;

#
# EOF
