package WoWUI::Module::BasicComboPoints;
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

    $self->global(1);
    $self->globalpc(1);

    return $self;

}

sub augment_global
{

    my $self = shift;

    my $config = $self->modconfig;
    $self->globaldata_set( bcp => $config->{basiccombopoints} );

    return;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    return 1;

}

# keep require happy
1;

#
# EOF
