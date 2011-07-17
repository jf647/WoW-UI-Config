#
# $Id: tif.pm 4986 2011-05-21 10:48:34Z james $
#

package WoWUI::Module::tif;
use Moose;

use strict;
use warnings;

use Carp 'croak';

# set up class
extends 'WoWUI::Module::Basic';
augment data => \&augment_data;
__PACKAGE__->meta->make_immutable;

# class attributes
__PACKAGE__->name( 'tif' );
__PACKAGE__->global( 1 );

sub augment_data
{

    my $self = shift;

    return { realms => $self->config->{realms} };

}

# keep require happy
1;

#
# EOF
