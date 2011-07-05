#
# $Id: Realm.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Realm;
use Moose;

use namespace::autoclean;

# set up class
has name => ( is => 'rw', isa => 'Str' );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has cfg => ( is => 'rw', isa => 'HashRef' );
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
use WoWUI::Util 'log';

# constructor
sub BUILD
{

  my $self = shift;
  my %p = @_;
  
  my $log = WoWUI::Util->log;

  $self->flags( Set::Scalar->new );

  for my $charname( keys %{ $p{chars} } ) {
    $log->debug("creating char object for $charname on ", $self->name);
    my $char = WoWUI::Char->new( name => $charname, realm => $self );
    if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, { include => [ 'everyone' ], exclude => [ qw|level:85 bankalt mule| ] } ) ) {
      $self->flags->insert("realm:still_leveling");
    }
    $self->char_set( $charname => $char );
  }
  for my $char( $self->chars_values ) {
    $char->flags_get(0)->insert( $self->flags->members );
  }

}   

# keep require happy
1;

#
# EOF
