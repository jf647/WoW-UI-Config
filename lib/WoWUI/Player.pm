#
# $Id: Machine.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Machine;
use Moose;

use namespace::autoclean;

# set up class
has name => ( is => 'rw', isa => 'Str', required => 1 );
has account => ( is => 'rw', isa => 'Str', required => 1 );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has realms => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Realm]'
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        realm_get => 'get',
        realm_set => 'set',
        realms => 'keys',
        realm_values => 'values',
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
        modoptions => 'keys',
        modoptions_values => 'values',
    },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Path::Class qw|dir file|;

use WoWUI::Util qw|log load_file expand_path|;

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
    my $playercfg = load_file( expand_path( file( $cfg->{dirs}->{playerdir}, $self->name . '.yaml' ) ) );
    
    return $self;

}

# keep require happy
1;

#
# EOF
