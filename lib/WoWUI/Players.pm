#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Players;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has players => (
  is => 'bare',
  isa => 'HashRef[WoWUI::Player]',
  default => sub { {} },
  traits => ['Hash'],
  handles => {
    player_get => 'get',
    player_set => 'set',
    players => 'values',
    player_names => 'keys',
  },
);

use Carp 'croak';

use WoWUI::Util qw|log expand_path load_file|;

before player_get => sub {

    my $self = shift;
    my $playername = shift;

    my $log = WoWUI::Util->log;
    
    unless( exists $self->{players}->{$playername} ) {
        $log->debug("constructing player object for $playername");
        my $player = WoWUI::Player->new( $playername );
        $self->player_set( $playername, $player );
    }
    
};

# keep require happy
1;

#
# EOF
