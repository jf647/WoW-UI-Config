#
# $Id: Realm.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Realm;
use Moose;

use namespace::autoclean;

# set up class
has name => ( is => 'rw', isa => 'Str', required => 1 );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has cfg => ( is => 'rw', isa => 'HashRef' );
has player => ( is => 'rw', isa => 'WoWUI::Player', required => 1 );
has chars => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Char]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        char_set => 'set',
        char_get => 'get',
        char_names => 'keys',
        chars => 'values',
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
    modoption_exists => 'exists',
    modoptions_list => 'keys',
    modoptions_values => 'values',
  },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Char;
use WoWUI::Config;
use WoWUI::Util 'log';
use WoWUI::Filter;
use WoWUI::Filter::Constants qw|F_CALL|;

# constructor
sub BUILD
{

    my $self = shift;
  
    my $log = WoWUI::Util->log;
    my $gcfg = WoWUI::Config->instance->cfg;

    $self->flags( Set::Scalar->new );

    for my $mod( keys %{ $self->cfg->{modoptions} } ) {
        $self->modoption_set( $mod, $self->cfg->{modoptions}->{$mod} );
    }

    for my $charname( keys %{ $self->cfg->{chars} } ) {
        $log->debug("creating char object for $charname on ", $self->name);
        my $char = WoWUI::Char->new( name => $charname, realm => $self, cfg => $self->cfg->{chars}->{$charname} );
        my $levelcap = $gcfg->{levelcap};
        my $f = WoWUI::Filter->new( char => $char );
        if( $f->match( { filter => { exclude => [ qw|level:$levelcap bankalt mule| ] } }, F_CALL ) ) {
            $self->flags->insert("realm:still_leveling");
        }
        $self->char_set( $charname => $char );
    }

}   

# keep require happy
1;

#
# EOF
