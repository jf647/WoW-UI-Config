#
# $Id: Auctionator.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Auctionator;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

# class attributes
sub BUILD
{

    my $self = shift;
    $self->name( 'auctionator' );
    $self->perchar( 1 );
    
    return $self;

}

# keep require happy
1;

#
# EOF
