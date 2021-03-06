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

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->perchar( 1 );
    
    my $config = $self->config;

    for my $npc( keys %{ $config->{npcs} } ) {
        for my $setname( @{ $config->{npcs}->{$npc}->{sets} } ) {
            if( my $npcset = $self->set_get($setname) ) {
                $npcset->insert( $npc );
            }
            else {
                my $npcset = Set::Scalar->new( $npc );
                $self->set_set( $setname, $npcset );
            }
        }
    }    
    
    return $self;

}

sub augment_perchar
{

  my $self = shift;
  my $char = shift;
  my $f = shift;

  my $config = $self->modconfig( $char );
  my $o = $self->modoptions( $char );

  my $npcs;
  my $achievements;

  # achievements
  for my $achievement( keys %{ $config->{achievements} } ) {
      my %wantedmap = map { $_ => 1 } @{ $o->{achievements} };
      my $enabled = exists $wantedmap{$achievement} ? 1 : 0;
      push @$achievements, {
          id => $config->{achievements}->{$achievement}->{id},
          enabled => $enabled,
      }
  }

  # sets / npcs
  my $npcset = Set::Scalar->new;
  for my $setname( @{ $o->{sets} } ) {
      if( $setname =~ m/^([-\+])?(@)?(.+)$/x ) {
          my( $op, $isgroup, $name ) = ( $1, $2, $3 );
          if( $isgroup ) {
              my $npcnames;
              unless( $npcnames = $self->set_get($name) ) {
                  croak "bad NPC set '$name'";
              }
              for my $npcname( $npcnames->members ) {
                  if( '+' eq $op ) {
                      $npcset->insert( $npcname );
                  }
                  else {
                      $npcset->delete( $npcname )
                  }
              }
          }
          else {
              unless( exists $config->{npcs}->{$name} ) {
                  croak "bad NPC name '$name'";
              }
              if( '+' eq $op ) {
                  $npcset->insert( $name );
              }
              else {
                  $npcset->delete( $name );
              }
          }
      }
     }
  
  for my $npcname( $npcset->members ) {
      if( 'ARRAY' eq ref $config->{npcs}->{$npcname}->{id} ) {
          for my $id( @{ $config->{npcs}->{$npcname}->{id} } ) {
              my $npc = { name => $npcname, id => $id };
              if( exists $config->{npcs}->{$npcname}->{world} ) {
                  $npc->{world} = $config->{npcs}->{$npcname}->{world};
                  if( $npc->{world} !~ m/^\d+/x ) {
                      $npc->{world} = qq{"$npc->{world}"};
                  }
              }
              push @$npcs, $npc;
          }
      }
      else {
          my $npc = {
              name => $npcname,
              id => $config->{npcs}->{$npcname}->{id},
          };
          if( exists $config->{npcs}->{$npcname}->{world} ) {
              $npc->{world} = $config->{npcs}->{$npcname}->{world};
              if( $npc->{world} !~ m/^\d+/x ) {
                  $npc->{world} = qq{"$npc->{world}"};
              }
          }
          push @$npcs, $npc;
      }
  }

  $self->perchardata_set( npcs => $npcs, achievements => $achievements );
  
  return;

}

# keep require happy
1;

#
# EOF
