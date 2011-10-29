#
# $Id$
#

package WoWUI::Module::KeyBindings;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;

    my $config = $self->config;
  
    $self->global( 1 );
    $self->perchar( 1 );

    return $self;

}

sub augment_global
{

    my $self = shift;

    my $config = $self->modconfig;
  
    if( $config->{bindingmode} eq 'global' ) {
        $self->augment_global_global;
    }
    elsif( $config->{bindingmode} eq 'perchar' ) {
        $self->augment_global_perchar;
    }
    else {
        croak "invalid binding mode '$config->{bindingmode}'";
    }

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $config = $self->modconfig;

    if( $config->{bindingmode} eq 'global' ) {
        $self->augment_perchar_global;
    }
    elsif( $config->{bindingmode} eq 'perchar' ) {
        $self->augment_perchar_perchar;
    }
    else {
        croak "invalid binding mode '$config->{bindingmode}'";
    }

}


sub augment_global_global
{
    my $self = shift;
    my $config = $self->modconfig;

    my %data;
    $self->build_all( \%data, $config );
    $self->globaldata_set( bindingmode => 'global', %data );

}

sub augment_perchar_perchar
{

    my $self = shift;
    my $char = shift;
    my $config = $self->modconfig( $char );

    my %data;
    $self->build( \%data, $config );
    $self->perchardata_set( %data );

}

sub augment_global_perchar
{

    my $self = shift;
    
    $self->globaldata_set( bindingmode => 'perchar' );

}

sub augment_perchar_global
{

    my $self = shift;
    
    $self->perchardata_set( bindingmode => 'global' );

}

sub build_all
{

    my $self = shift;
    my $data = shift;
    my $config = shift;
    
    $self->build_bindings($data, $config);
    $self->unbind_keys($data, $config);
    $self->build_modifiedclicks($data, $config);

}

sub build_bindings
{

    my $self = shift;
    my $data = shift;
    my $config = shift;

    my %bindings;
    
    for my $binding( keys %{ $config->{bind} } ) {
        my $key = $config->{bind}->{$binding};
        if( exists $config->{aliases}->{$binding} ) {
            $binding = $config->{aliases}->{$binding};
        }
        if( ref $key ) {
            for my $k( @$key ) {
                $bindings{$k} = $binding;
            }
        }
        else {
            $bindings{$key} = $binding;
        }
    }

    $data->{bindings} = \%bindings;

}

sub unbind_keys
{

    my $self = shift;
    my $data = shift;
    my $config = shift;

    for my $unbind( @{ $config->{unbind} } ) {
        $data->{bindings}->{$unbind} = 'NONE';
    }

}

sub build_modifiedclicks
{

    my $self = shift;
    my $data = shift;
    my $config = shift;
    
    my %modifiedclicks;
    
    for my $mod( keys %{ $config->{modifiedclick} } ) {
        my $key = $config->{modifiedclick}->{$mod};
        $modifiedclicks{$key} = $mod;
    }
    
    $data->{modifiedclicks} = \%modifiedclicks;

}

#
# EOF
