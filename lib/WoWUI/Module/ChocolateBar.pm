#
# $Id: ChocolateBar.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::ChocolateBar;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
has 'plugins' => ( is => 'rw', isa => 'HashRef' );
has 'all_plugins' => ( is => 'rw', isa => 'Object' );
CLASS->meta->make_immutable;

use Clone qw|clone|;
use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD {

    my $self = shift;
    
    $self->global( 1 );
    $self->globalpc( 1 );

    $self->augment_config;
    $self->build_plugin_list();

    return $self;

}

sub augment_global
{

    my $self = shift;

    my $o = $self->modoptions;

    $self->globaldata_set(
        font => $o->{font},
        fontsize => $o->{fontsize},
        fontname => $o->{fontname},
    );

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $config = $self->modconfig( $char );
    my $log = WoWUI::Util->log;

    my $plugins = Set::Scalar->new;
    for my $plugin( keys %{ $config->{plugins} } ) {
        if( exists $config->{plugins}->{$plugin}->{filter} ) {
            if( $f->match( $config->{plugins}->{$plugin}->{filter} ) ) {
                $plugins->insert( $plugin );
            }
        }
    }
    my @plugins;
    my $max_index = $self->add_sorted(\@plugins, $plugins, 'left') || 1;
    $self->add_sorted(\@plugins, $plugins, 'center');
    $self->add_sorted(\@plugins, $plugins, 'right', 1);
    my $disabled = $self->all_plugins - $plugins;
    for my $plugin( $disabled->members ) {
        if( exists $config->{plugins}->{$plugin}->{altname} ) {
            push @plugins, {
                name => $config->{plugins}->{$plugin}->{altname},
                align => 'left',
                enabled => 0,
                notext => 1,
                index => ++$max_index
            };
        }
        else {
            push @plugins, {
                name => $plugin,
                align => 'left',
                enabled => 0,
                notext => 1,
                index => ++$max_index
            };
        }
    }

    if( $log->is_debug ) {
        for my $align( qw|left center right| ) {
            my @temp;
            for my $plugin( @plugins ) {
                next unless( $align eq $plugin->{align} );
                next if( exists $plugin->{enabled} && 0 ==  $plugin->{enabled} );
                push @temp, $plugin;
            }
            for my $plugin( sort { $a->{index} <=> $b->{index} } @temp ) {
                $log->debug($char->realm, " - $char - $align/$plugin->{index}: $plugin->{name}");
            }
        }
    }

    $self->globaldata->{realms}->{$char->realm->name}->{$char->name}->{plugins} = \@plugins;

}

sub augment_config
{

    my $self = shift;
    my $config = $self->config;
  
    for my $plugin( keys %{ $config->{plugins} } ) {
        $config->{plugins}->{$plugin}->{name} = $plugin;
    }

}

sub build_plugin_list
{

    my $self = shift;

    my $config = $self->config;

    my %plugins;
    my $all_plugins = Set::Scalar->new;

    for my $plugin( keys %{ $config->{plugins} } ) {
        $plugins{$plugin} = $config->{plugins}->{$plugin};
        $all_plugins->insert( $plugin );
    }
  
    $self->plugins( \%plugins );
    $self->all_plugins( $all_plugins );

}

sub add_sorted
{

    my $self = shift;
    my $data = shift;
    my $plugins = shift;
    my $align = shift;
    my $reverse = 1;
  
    my $config = $self->modconfig;
  
    my @data;
    for my $plugin( $plugins->members ) {
        unless( exists $config->{plugins}->{$plugin} ) {
            croak "unknown plugin '$plugin'";
        }
        next unless( $config->{plugins}->{$plugin}->{align} eq $align );
        push @data, clone $config->{plugins}->{$plugin};
    }
    if( $reverse ) {
        @data = sort { $b->{priority} <=> $a->{priority} } @data;
        my $i = scalar @data;
        for( @data ) { $_->{index} = $i-- };
        push @$data, @data;
    }
    else {
        @data = sort { $a->{priority} <=> $b->{priority} } @data;
        my $i = 1;
        for( @data ) { $_->{index} = $i++ };
        push @$data, @data;
    }
  
    return scalar @data;

}

# keep require happy
1;

#
# EOF
