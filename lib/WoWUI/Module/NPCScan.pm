#
# $Id: NPCScan.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::NPCScan;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
has 'sets' => (
  traits => ['Hash'],
  is => 'bare',
  isa => 'HashRef[Set::Scalar]',
  default => sub { {} },
  handles => {
    set_get => 'get',
    set_set => 'set',
    set_list => 'keys',
  },
);
CLASS->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util 'log';

# class attributes
CLASS->perchar( 1 );

# constructor
sub BUILD
{

    my $self = shift;
    
    my $config = $self->config;

    for my $npc( keys %{ $config->{npcs} } ) {
        for my $setname( @{ $config->{npcs}->{$npc}->{sets} } ) {
            if( my $set = $self->set_get($setname) ) {
                $set->insert( $npc );
            }
            else {
                my $set = Set::Scalar->new( $npc );
                $self->set_set( $setname, $set );
            }
        }
    }    
    
    return $self;

}

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $config = $self->config;
  my $o = $char->modoption_get($self->name);

  my $chardata = { realm => $char->realm->name, char => $char->name };

  # achievements
  for my $achievement( keys %{ $config->{achievements} } ) {
      my %wantedmap = map { $_ => 1 } @{ $o->{achievements} };
      my $enabled = exists $wantedmap{$achievement} ? 1 : 0;
      push @{ $chardata->{achievements} }, {
          id => $config->{achievements}->{$achievement}->{id},
          enabled => $enabled,
      }
  }

  # sets / npcs
  my $npcs = Set::Scalar->new;
  for my $setname( @{ $o->{sets} } ) {
      $setname =~ m/^([-\+])?(@)?(.+)$/;
      my( $op, $isgroup, $name ) = ( $1, $2, $3 );
      if( $isgroup ) {
          my $set;
          unless( $set = $self->set_get($name) ) {
              croak "bad NPC set '$name'";
          }
          for my $npcname( $set->members ) {
              if( '+' eq $op ) {
                  $npcs->insert( $npcname );
              }
              else {
                  $npcs->delete( $npcname )
              }
          }
      }
      else {
          unless( exists $config->{npcs}->{$name} ) {
              croak "bad NPC name '$name'";
          }
          if( '+' eq $op ) {
              $npcs->insert( $name );
          }
          else {
              $npcs->delete( $name );
          }
      }
  }
  
  for my $npcname( $npcs->members ) {
      if( 'ARRAY' eq ref $config->{npcs}->{$npcname}->{id} ) {
          for my $id( @{ $config->{npcs}->{$npcname}->{id} } ) {
              my $npc = { name => $npcname, id => $id };
              if( exists $config->{npcs}->{$npcname}->{world} ) {
                  $npc->{world} = $config->{npcs}->{$npcname}->{world};
                  if( $npc->{world} !~ m/^\d+/ ) {
                      $npc->{world} = qq{"$npc->{world}"};
                  }
              }
              push @{ $chardata->{npcs} }, $npc;
          }
      }
      else {
          my $npc = {
              name => $npcname,
              id => $config->{npcs}->{$npcname}->{id},
          };
          if( exists $config->{npcs}->{$npcname}->{world} ) {
              $npc->{world} = $config->{npcs}->{$npcname}->{world};
              if( $npc->{world} !~ m/^\d+/ ) {
                  $npc->{world} = qq{"$npc->{world}"};
              }
          }
          push @{ $chardata->{npcs} }, $npc;
      }
  }

  return $chardata;

}

# keep require happy
1;

#
# EOF
