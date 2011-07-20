#
# $Id: Hydra.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Hydra;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
__PACKAGE__->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
__PACKAGE__->name( 'hydra' );
__PACKAGE__->global( 1 );
__PACKAGE__->perchar( 1 );

sub augment_data
{

  my $self = shift;

  my $config = $self->config;
  my $o = $self->modoptions;
  my $log = WoWUI::Util->log;

  my $data;
  for my $realm( $self->player->realms ) {
    for my $char( $realm->chars ) {
        if( WoWUI::Util::Filter::matches( $char->flags_get(0), $char, { include => [ 'dualbox' ] } ) ) {
            $log->trace("adding self char ", $char->name, " to trust list for realm ", $realm->name);
            $data->{hydra}->{$realm->name}->{$char->name} = 1;
        }
    }
  }
  if( exists $o->{extratrust} ) {
      for my $realm( keys %{ $o->{extratrust} } ) {
          for my $char( @{ $o->{extratrust}->{$realm} } ) {
              $log->trace("adding extra char $char to trust list for realm $realm");
              $data->{hydra}->{$realm}->{$char} = 1;
          }
      }
  }

  return $data;

}

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $config = $self->config;

  # Hydra master/slave
  if( WoWUI::Util::Filter::matches( $char->flags_get(0), $char, { include => [ 'all(machine:type:master;dualbox:master)' ] } ) ) {
      return { realm => $char->realm->name, char => $char->name, hydra => 1, master => 1, slave => 0 };
  }
  elsif( WoWUI::Util::Filter::matches( $char->flags_get(0), $char, { include => [ 'all(machine:type:slave;dualbox:slave)' ] } ) ) {
      return { realm => $char->realm->name, char => $char->name, hydra => 1, master => 0, slave => 1 };
  }
  
  return;

}

# keep require happy
1;

#
# EOF
