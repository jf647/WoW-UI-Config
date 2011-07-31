#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machine;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
with 'WoWUI::ModOptions';
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
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Players;
use WoWUI::Util qw|log load_file expand_path|;

# constructor
sub BUILDARGS
{

    my $class = shift;
    my $machname = shift;
    my $playernames = shift;

    # expand players
    my %players;
    for my $playername( @$playernames ) {
        my $player = WoWUI::Players->instance->player_get( $playername );
        $players{$playername} = $player;
    }
    return { name => $machname, players => \%players };

}
sub BUILD
{

    my $self = shift;

    my $config = WoWUI::Config->instance->cfg;
    my $log = WoWUI::Util->log;
    $log->debug("creating machine object for ", $self->name);

    # load our machine config file
    my $machinefile = expand_path( $config->{dirs}->{machinedir} )->file( $self->name . '.yaml' );
    unless( -f $machinefile ) {
        croak "no such machine file $machinefile";
    }
    my $cfg = load_file( $machinefile );

    # set our various options
    $self->modoptions_set( $cfg );
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

    return $self;

}   

# keep require happy
1;

#
# EOF
