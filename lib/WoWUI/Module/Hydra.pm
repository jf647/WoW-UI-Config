#
# $Id: Hydra.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Hydra;
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
    
    $self->global( 1 );
    $self->perchar( 1 );
    
    return $self;
    
}

sub augment_global
{

    my $self = shift;

    my $o = $self->modoptions;
    my $log = WoWUI::Util->logger;

    my $extratrust = $self->globaldata_get( 'extratrust' ) || {};
    
    my %seen;
    for my $realm( $self->player->realms ) {
        next if( exists $seen{$realm->name} );
        $seen{$realm->name} = 1;
        for my $char( $realm->chars ) {
            my $f = WoWUI::Filter->new( char => $char, machine => $self->machine );
            if( $f->match( { include => [ 'dualbox' ] }, F_C0 ) ) {
                $extratrust->{$realm->name}->{$char->name} = 1;
            }
        }
    }
    
    if( exists $o->{extratrust} ) {
        for my $realm( keys %{ $o->{extratrust} } ) {
            for my $char( @{ $o->{extratrust}->{$realm} } ) {
                $log->trace("adding extra char $char to trust list for realm $realm");
                $extratrust->{$realm}->{$char} = 1;
            }
        }
    }

    $self->globaldata_set( extratrust => $extratrust );

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    # Hydra master/slave
    if( $f->match( { include => [ 'all(machine:type:primary;dualbox)' ] }, F_C0|F_MACH ) ) {
        $self->perchardata_set( hydra => 1, master => 1, slave => 0 );
    }
    elsif( $f->match( { include => [ 'all(machine:type:secondary;dualbox)' ] }, F_C0|F_MACH ) ) {
        $self->perchardata_set( hydra => 1, master => 0, slave => 1 );
    }

}

# keep require happy
1;

#
# EOF
