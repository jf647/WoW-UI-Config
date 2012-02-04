package WoWUI::Module::kgPanels;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

use WoWUI::ProfileSet;
use WoWUI::Filter::Constants;

# set up class
extends 'WoWUI::Module::Base';
has panels => (
    is => 'bare',
    isa => 'HashRef[HashRef]',
    traits => ['Hash'],
    handles => {
        panel_get => 'get',
        panel_set => 'set',
        panel_exists => 'exists',
    },
);
has layouts => (
    is => 'bare',
    isa => 'HashRef[HashRef]',
    traits => ['Hash'],
    handles => {
        layout_get => 'get',
        layout_set => 'set',
        layout_exists => 'exists',
        layout_names => 'keys',
    },
);
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

    $self->globaldata_set( kgp => $self );

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $profile = $self->build_profile( $char, $f );
    
    my $pname = $self->profileset->store( $profile, 'KGPLayout' );
    $self->globaldata_get( 'chars' )->{$char->dname} = $pname;

}

sub build_profile
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
    
    my $config = $self->modconfig( $char );
    my $o = $self->modoptions( $char );
    
    # find the layout for this char
    my $layout;
    for my $lname( keys %{ $config->{layouts} } ) {
        my $ldata = $config->{layouts}->{$lname};
        if( $f->match( $ldata->{filter} ) ) {
            if( $layout ) {
                croak $char->name, "matched layout '$lname' after matching '$layout'";
            }
            $layout = $lname;
            
        }
    }
    
    # build the layout if it doens't already exist
    unless( $self->layout_exists( $layout ) ) {
        $self->build_layout( $layout, $char );
    }

    return { layout => $layout };

}

sub build_layout
{

    my $self = shift;
    my $lname = shift;
    my $char = shift;
    
    my $config = $self->modconfig( $char );

    # build any panels that don't already exist
    for my $pname( @{ $config->{layouts}->{$lname}->{panels} } ) {
        unless( $self->panel_exists( $pname ) ) {
            $self->build_panel( $pname, $char );
        }
    }
    
    $self->layout_set( $lname, {
        name => $lname,
        panels => $config->{layouts}->{$lname}->{panels},
    } );

}

sub build_panel
{

    my $self = shift;
    my $pname = shift;
    my $char = shift;
    
    my $panel = $self->modconfig( $char )->{panels}->{$pname};
    $panel->{name} = $pname;

    $self->panel_set( $pname, $panel );

}
