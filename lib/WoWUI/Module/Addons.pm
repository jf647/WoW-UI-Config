#
# $Id: Addons.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Addons;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

# set up class
extends 'WoWUI::Module::Base';
has 'all_addons' => ( is => 'rw', isa => 'Object' );
has 'named_sets' => (
  traits => ['Hash'],
  is => 'bare',
  isa => 'HashRef[Set::Scalar]',
  default => sub { {} },
  handles => {
    named_get => 'get',
    named_set => 'set',
    named_list => 'keys',
    named_values => 'values',
    named_count => 'count',
  },
);
has 'class_sets' => (
  traits => ['Hash'],
  is => 'bare',
  isa => 'HashRef[Set::Scalar]',
  default => sub { {} },
  handles => {
    class_get => 'get',
    class_set => 'set',
    class_list => 'keys',
    class_values => 'values',
    class_count => 'count',
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

  my $config = $self->config;
  
  $self->global( 1 );
  $self->perchar( 1 );

  $self->all_addons( Set::Scalar->new( keys %{ $config->{addons} } ) );

  return $self;

}

sub augment_global
{

  my $self = shift;

  my $o = $self->modoptions;

  # do we have too many named sets?
  if( $self->named_count > $o->{max_sets} ) {
    croak "selected ", $self->named_count, " sets but we can only support $o->{max_sets}";
  }

  # named sets
  for my $setname( $self->named_list ) {
    my $set = { name => $setname, addons => [] };
    for my $addon( $self->named_get( $setname )->elements ) {
      push @{ $set->{addons} }, $addon;
    }
    push @{ $self->globaldata->{named_sets} }, $set;
  }

  # class sets
  for my $setname( $self->class_list ) {
    my $set = { name => $setname, addons => [] };
    for my $addon( $self->class_get( $setname )->elements ) {
      push @{ $set->{addons} }, $addon;
    }
    push @{ $self->globaldata->{class_sets} }, $set;
  }
  
}

sub augment_perchar
{

  my $self = shift;
  my $char = shift;
  my $f = shift;

  my $config = $self->modconfig( $char );

  my $log = WoWUI::Util->log;

  my $enabled = Set::Scalar->new;
  for my $addon( $self->all_addons->elements ) {
  
    if( $f->match( $config->{addons}->{$addon} ) ) {
      $log->trace("picked up $addon");
      $enabled->insert($addon);
      if( exists $config->{addons}->{$addon}->{group} ) {
        if( 'ARRAY' eq ref $config->{addons}->{$addon}->{group} ) {
          for my $group( @{ $config->{addons}->{$addon}->{group} } ) {
            $self->add_to_named_set($group, $addon);
          }
        }
        else {
            $self->add_to_named_set($config->{addons}->{$addon}->{group}, $addon);
        }
      }
      if( exists $config->{addons}->{$addon}->{class} ) {
        if( 'ARRAY' eq ref $config->{addons}->{$addon}->{class} ) {
          for my $group( @{ $config->{addons}->{$addon}->{group} } ) {
            $self->add_to_class_set($group, $addon);
          }
        }
        else {
          $self->add_to_class_set($config->{addons}->{$addon}->{class}, $addon);
        }
      }
    }
    else {
      $log->trace("excluding $addon");
    }
  
  }
  
  my $disabled = $self->all_addons - $enabled;

  my @addons;
  push @addons, map { { name => $_, enabled => 1 } } $enabled->members;
  push @addons, map { { name => $_, enabled => 0 } } $disabled->members;
  $self->perchardata->{addons} = [ sort { $a->{name} cmp $b->{name} } @addons ];
  $char->addons( $enabled->clone );

}

sub add_to_named_set
{

  my $self = shift;
  my $setname = shift;
  my $addon = shift;
  
  if( my $set = $self->named_get($setname) ) {
    $set->insert($addon);
  }
  else {
    my $set = Set::Scalar->new($addon);
    $self->named_set($setname, $set);
  }

}

sub add_to_class_set
{

  my $self = shift;
  my $setname = shift;
  my $addon = shift;
  
  if( my $set = $self->class_get($setname) ) {
    $set->insert($addon);
  }
  else {
    my $set = Set::Scalar->new($addon);
    $self->class_set($setname, $set);
  }

}

# keep require happy
1;

#
# EOF
