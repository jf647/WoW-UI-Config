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
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Char;
use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;
    my $p = shift;
  
    my $log = WoWUI::Util->log;
    my $gcfg = WoWUI::Config->instance->cfg;

    $self->flags( Set::Scalar->new );

    for my $charname( keys %{ $p->{charnames} } ) {
        $log->debug("creating char object for $charname on ", $self->name);
        my $char = WoWUI::Char->new( name => $charname, realm => $self );
        my $levelcap = $gcfg->{levelcap};
        if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, { include => [ 'everyone' ], exclude => [ qw|level:$levelcap bankalt mule| ] } ) ) {
            $self->flags->insert("realm:still_leveling");
        }
        $self->char_set( $charname => $char );
    }
    for my $char( $self->chars ) {
        $char->flags_get(0)->insert( $self->flags->members );
    }

}   

# keep require happy
1;

#
# EOF
