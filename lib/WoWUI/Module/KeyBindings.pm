#
# $Id$
#

package WoWUI::Module::Addons;
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
  
  # iterate over keys
  
  # unbind keys
  
  # iterate over modified clicks

}

sub augment_perchar
{

  my $self = shift;
  my $char = shift;
  my $f = shift;

  my $config = $self->modconfig( $char );
  my $log = WoWUI::Util->log;

}

sub build_bindings
{

    my $config = shift;

    my %bindings;
    
    for my $binding( keys %{ $config->{bind}

    return \%bindings;

}

#
# EOF
