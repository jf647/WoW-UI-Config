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

    return $self;

}

sub augment_global
{

    my $self = shift;

    $self->augment_global_global;

}

sub augment_global_global
{
    my $self = shift;
    my $config = $self->modconfig;

    my %data;
    $self->build_all( \%data, $config );
    $self->globaldata_set( bindingmode => 'global', %data );

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

    for my $key( keys %{ $config->{bind} } ) {
        my $bind = $config->{bind}->{$key};
        if( exists $config->{aliases}->{$bind} ) {
            $bind = $config->{aliases}->{$bind};
        }
        $bindings{$key} = $bind;
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
