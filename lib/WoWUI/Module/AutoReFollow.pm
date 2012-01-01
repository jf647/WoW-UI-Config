package WoWUI::Module::AutoReFollow;
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
    
    $self->perchardata_set( enabled => 0, mode => "master" );
    if( $f->match( { include => [ 'all(machine:type:primary;dualbox)' ] }, F_C0|F_MACH ) ) {
        $self->perchardata_set( enabled => 1 );
    }
    elsif( $f->match( { include => [ 'all(machine:type:secondary;dualbox)' ] }, F_C0|F_MACH ) ) {
        $self->perchardata_set( enabled => 1, mode => "slave" );
    }

}

# keep require happy
1;

#
# EOF
