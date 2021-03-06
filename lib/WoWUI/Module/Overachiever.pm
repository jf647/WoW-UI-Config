#
# $Id: Overachiever.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Overachiever;
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

    my $config = $self->modconfig;
    my $o = $self->modoptions;

    for my $achievement( @{ $config->{achievements} } ) {
        if( exists $o->{$achievement} ) {
            $self->globaldata_set( $achievement => 1 );
        }
        else {
            $self->globaldata_set( $achievement => 0 );
        }
    }

}

# keep require happy
1;

#
# EOF
