package WoWUI::Module::Dominos;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

use WoWUI::ProfileSet;
use WoWUI::Filter::Constants;

# set up class
extends 'WoWUI::Module::Base';
has profileset => (
    is => 'rw',
    isa => 'WoWUI::ProfileSet',
    default => sub { WoWUI::ProfileSet->new },
);
after 'globaldata_clear' => sub {
    my $self = shift;
    $self->globaldata_set( chars => {} );
};
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{
    
    my $self = shift;
    
    $self->global( 1 );
    $self->globalpc( 1 );
    $self->globaldata_clear;
    
    return $self;
    
}

sub augment_global
{

    my $self = shift;

    $self->globaldata_set( dominos => $self );

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $profile = $self->build_profile( $char, $f );
    
    my $pname = $self->profileset->store( $profile, 'Dominos' );
    $self->globaldata_get( 'chars' )->{$char->dname} = $pname;

}

sub build_profile
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
    
    my $config = $self->modconfig( $char );

    my $profile;
    
    # global settings
    for my $gs( keys %{ $config->{global_options} } ) {
        my $block = $config->{global_options}->{$gs};
        if( my $r = $f->match( $block->{filter}, F_CALL|F_MACH ) ) {
            $profile->{$gs} = $r->value;
        }
        else {
            croak "can't find value for section $gs!";
        }
    }
    
    # numbered bars
    for my $barnum( sort { $a <=> $b } keys %{ $config->{numberedbars} } ) {
        my $block = $config->{numberedbars}->{$barnum};
        if( my $r = $f->match( $block->{filter}, F_CALL|F_MACH ) ) {
            push @{ $profile->{numberedbars} }, $r->value;
        }
        else {
            croak "can't build numbered bar $barnum!";
        }
    }

    # named bars
    for my $barname( keys %{ $config->{namedbars} } ) {
        my $block = $config->{namedbars}->{$barname};
        if( my $r = $f->match( $block->{filter}, F_CALL|F_MACH ) ) {
            $profile->{namedbars}->{$barname} = $r->value;
        }
    }

    return $profile;

}
