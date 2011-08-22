#
# $Id: tif.pm 4986 2011-05-21 10:48:34Z james $
#

package WoWUI::Module::tif;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

use Carp 'croak';

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

    $self->globaldata->{realms} = $config->{realms};

}

# keep require happy
1;

#
# EOF
