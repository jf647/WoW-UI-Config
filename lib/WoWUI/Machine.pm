#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machine;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has 'name' => ( is => 'rw', isa => 'Str', required => 1 );
has 'account' => ( is => 'rw', isa => 'Str' );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has [ qw|type player configfile| ] => ( is => 'rw', isa => 'Str' );
has [ qw|master slave| ] => ( is => 'rw', isa => 'Bool', default => 0 );
has 'options' => ( is => 'rw', isa => 'HashRef' );
has wowversions => ( is => 'rw', isa => 'ArrayRef[Str]' );
has output => ( is => 'rw', isa => 'Path::Class::File' );
has 'modoptions' => (
  is => 'rw',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    modoption_set => 'set',
    modoption_get => 'get',
    modoptions_list => 'keys',
    modoptions_values => 'values',
  },
);
# causes problems - build is never called with 0.27 of MooseX::Singleton
#__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util qw|log expand_path|;

# constructor
sub BUILDARGS
{

  my $class = shift;
  return { name => shift };

}
sub BUILD
{

  my $self = shift;
  
  my $config = WoWUI::Config->instance->cfg;

  my $log = WoWUI::Util->log;
  $log->debug("creating machine object for ", $self->name);
  
  unless( exists $config->{profiles}->{$self->name} ) { 
    croak "no such machine profile '", $self->name, "'";
  }
  my $options = $self->options( $config->{profiles}->{$self->name} );

  $self->account( $options->{account} );

  $self->flags( Set::Scalar->new );
  $self->flags->insert('machine:name:'.$self->name);
  $self->output( expand_path( $options->{output} ) );
  $self->type( $options->{machinetype} );
  $self->configfile( $options->{configfile} );
  $self->flags->insert('machine:type:'.$options->{machinetype});
  if( 'master' eq $options->{machinetype} ) {
    $self->master(1);
  }
  elsif( 'slave' eq $options->{machinetype} ) {
    $self->slave(1);
  }
  $self->player( $options->{player} );
  $self->flags->insert('machine:player:'.$options->{player});
  $self->modoptions( $options->{modules} );
  $self->wowversions( $options->{wowversions} );
  for my $wowversion( @{ $options->{wowversions} } ) {
    $self->flags->insert('machine:wowversion:'.$wowversion);
  }

}   

# keep require happy
1;

#
# EOF
