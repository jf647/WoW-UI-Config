#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Player;
use Moose;

use namespace::autoclean;

# set up class
has name => ( is => 'rw', isa => 'Str', required => 1 );
has account => ( is => 'rw', isa => 'Str' );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has realms => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Realm]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        realm_get => 'get',
        realm_set => 'set',
        realm_names => 'keys',
        realms => 'values',
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
use Path::Class qw|dir file|;

use WoWUI::Util qw|log load_file expand_path|;
use WoWUI::Realm;

# constructor
sub BUILDARGS
{

    my $class = shift;
    my $playername = shift;
    return { name => $playername };

}

sub BUILD
{

    my $self = shift;
    
    my $cfg = WoWUI::Config->instance->cfg;
    my $playercfg = load_file( expand_path( '$PLAYERDIR/' . $self->name . '.yaml' ) );
    
    my $log = WoWUI::Util->log;
    
    # set our various options
    for my $mod( keys %{ $playercfg->{modoptions} } ) {
        $self->modoption_set( $mod, $cfg->{modoptions}->{$mod} );
    }
    $self->account( $playercfg->{account} );
    $self->flags( Set::Scalar->new );
    $self->flags->insert('player:name:'.$self->name);

    # iterate over realms
    for my $realmname( keys %{ $playercfg->{realms} } ) {
        $log->debug("creating realm object for $realmname");
        my $realm = WoWUI::Realm->new( name => $realmname, playercfg => $playercfg );
        $self->realm_set( $realmname, $realm );
    }

    return $self;

}

sub charlist
{

    my $self = shift;

    my %chars;
    for my $realm( $self->realms ) {
        for my $char( $realm->char_names ) {
            $chars{$realm->name}->{$char} = {};
        }
    }
  
    return \%chars;

}


# keep require happy
1;

#
# EOF
