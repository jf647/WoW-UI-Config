#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machine;
use Moose;

use namespace::autoclean;

# set up class
has name => ( is => 'rw', isa => 'Str', required => 1 );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has types => ( is => 'rw', isa => 'ArrayRef[Str]' );
has wowversions => ( is => 'rw', isa => 'ArrayRef[Str]' );
has output => ( is => 'rw', isa => 'Path::Class::File' );
has players => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Player]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        player_set => 'set',
        player_get => 'get',
        player_names => 'keys',
        players => 'values',
    },
);
has modoptions => (
  is => 'bare',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    modoption_set => 'set',
    modoption_get => 'get',
    modoption_names => 'keys',
  },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util qw|log load_file expand_path|;

sub BUILD
{

    my $self = shift;

    my $config = WoWUI::Config->instance->cfg;
    my $log = WoWUI::Util->log;
    $log->debug("creating machine object for ", $self->name);

    # if the machines singleton already has an object for this machine, just return it
    my $cur_mach = WoWUI::Machines->instance->machine_get( $self->name );
    if( 'WoWUI::Machine' eq reftype $cur_mach ) {
        $log->debug("using built machine object");
        return $cur_mach;
    }

    # load our machine config file
    my $machinefile = expand_path( $config->{dirs}->{machinedir} )->file( $self->name . '.yaml' );
    unless( -f $machinefile ) {
        croak "no such machine file $machinefile";
    }
    my $cfg = load_file( $machinefile );

    # set our various options
    for my $mod( keys %{ $cfg->{modules} } ) {
        $self->modoption_set( $mod, $cfg->{modules}->{$mod} );
    }
    $self->flags( Set::Scalar->new );
    $self->flags->insert('machine:name:'.$self->name);
    $self->output( expand_path( $cfg->{output} ) );
    $self->types( $cfg->{types} );
    for my $type( @{ $self->types } ) {
        $self->flags->insert("machine:type:$type");
    }
    $self->wowversions( $cfg->{wowversions} );
    for my $wowversion( @{ $cfg->{wowversions} } ) {
        $self->flags->insert('machine:wowversion:'.$wowversion);
    }
    
    # expand players
    for my $playername( @{ $cur_mach->{players} } ) {
        my $player = WoWUI::Players->instance->player_get( $playername );
        $self->flags->insert( "player:$playername" );
        $self->player_set( $playername, $player );
    }

    # store this machine in the machines singleton
    WoWUI::Machines->instance->machine_set( $self->name, $self );

    return $self;

}   

# keep require happy
1;

#
# EOF
