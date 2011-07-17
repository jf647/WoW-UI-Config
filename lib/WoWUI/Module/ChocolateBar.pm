#
# $Id: ChocolateBar.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::ChocolateBar;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
has 'plugins' => ( is => 'rw', isa => 'HashRef' );
has 'all_plugins' => ( is => 'rw', isa => 'Object' );
augment data => \&augment_data;
__PACKAGE__->meta->make_immutable;

use Clone qw|clone|;
use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'chocolatebar' );
__PACKAGE__->global( 1 );

# constructor
sub BUILD {

    my $self = shift;

    $self->augment_config;
    $self->build_plugin_list();

    return $self;

}

sub augment_data
{

    my $self = shift;

    my $config = $self->config;
    my $o = $self->modoptions;

    my $log = WoWUI::Util->log;

    my $data = {
        font => $o->{font},
        fontsize => $o->{fontsize},
        fontname => $o->{fontname},
    };

    for my $realm( $self->player->realms ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars ) {
            if( exists $config->{perchar_criteria} ) {
                next unless( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{perchar_criteria} ) );
            }
            $log->debug("processing character ", $char->name);
            my $plugins = Set::Scalar->new;
            for my $plugin( keys %{ $config->{plugins} } ) {
                if( exists $config->{plugins}->{$plugin}->{criteria} ) {
                    if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{plugins}->{$plugin}->{criteria} ) ) {
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
                        $log->debug("$realm - $char - $align/$plugin->{index}: $plugin->{name}");
                    }
                }
            }

            $data->{realms}->{$realm->name}->{$char->name}->{plugins} = \@plugins;
            
        }

    }

    return $data;

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
  
  my $config = $self->config;
  
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
