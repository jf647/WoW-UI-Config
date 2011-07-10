#
# $Id: Bagnon.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Bagnon;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Basic';
augment chardata => \&augment_chardata;
__PACKAGE__->meta->make_immutable;

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'bagnon', global => 0, perchar => 1 };
}

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $config = $self->config;
  # XXX
  my $o = WoWUI::Machine->instance->modoption_get($self->name);

  
  # money frame defaults to on
  my $moneyframe = 1;
  # turn off the money frame for master machines on chars that have broker_currency enabled
  if( WoWUI::Util::Filter::matches( $char->flags_get('common'), $char, { addons => [ 'Broker_Currency' ], include => [ 'machine:type:master' ] } ) ) {
    $moneyframe = 0;
  }

  # scale
  my $scale = 1.0;
  if( exists $o->{scale} ) {
    $scale = $o->{scale};
  }

  return { realm => $char->realm->name, char => $char->name, scale => $scale, moneyframe => $moneyframe };

}

# keep require happy
1;

#
# EOF
