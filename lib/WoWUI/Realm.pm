#
# $Id: Realm.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Realm;
use Moose;

use namespace::autoclean;

# set up class
has 'name' => ( is => 'rw', isa => 'Str' );
has flags => ( is => 'rw', isa => 'Set::Scalar' );
has options => ( is => 'rw', isa => 'HashRef' );
has 'chars' => (
  is => 'rw',
  isa => 'HashRef[WoWUI::Char]',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    char_set => 'set',
    char_get => 'get',
    chars_list => 'keys',
    chars_values => 'values',
  },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Char;
use WoWUI::Config;
use WoWUI::Util 'log';

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
  my $profile = WoWUI::Profile->instance->options;
  
  my $log = WoWUI::Util->log;

  $self->flags( Set::Scalar->new );
  my $options = $self->options( $profile->{realm}->{$self->{name}} );

  for my $charname( keys %{ $options } ) {
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
