#
# $Id: Profile.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Profile;
use MooseX::Singleton;

use namespace::autoclean;

# set up class
has 'file' => ( is => 'rw', isa => 'Str' );
has 'options' => ( is => 'rw', isa => 'HashRef' );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has 'realms' => (
  is => 'rw',
  isa => 'HashRef[WoWUI::Realm]',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    realm_set => 'set',
    realm_get => 'get',
    realms_list => 'keys',
    realms_values => 'values',
  },
);
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

use WoWUI::Realm;
use WoWUI::Util qw|expand_path load_file log|;

# constructor
sub BUILDARGS
{

    my $class = shift;
    return { file => shift };

}
sub BUILD
{

    my $self = shift;

    $self->flags( Set::Scalar->new );

    my $options = $self->options( load_file( expand_path( $self->file ) ) );
    $self->modoptions( $options->{modules} || {} );

}

# popupate realms
sub populate
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    for my $realmname( keys %{ $self->options->{realm} } ) {
        $log->debug("creating realm object for $realmname");
        my $realm = WoWUI::Realm->new( $realmname );
        $self->realm_set( $realmname => $realm );
    }

}

# a simple hash of realms and chars
sub charlist
{

    my $self = shift;

    my %chars;
    for my $realm( $self->realms_values ) {
        for my $char( $realm->chars_list ) {
            $chars{$realm->name}->{$char} = {};
        }
    }
  
    return \%chars;

}

# keep require happy
1;

#
# EOF
