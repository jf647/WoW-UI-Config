#
# $Id: Bagnon.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Bagnon;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->perchar( 1 );
    
    return $self;

}

sub augment_perchar
{

  my $self = shift;
  my $char = shift;
  my $f = shift;

  my $config = $self->modconfig( $char );
  my $o = $self->modoptions( $char );
  
  my $mf = $f->match( $config->{moneyframe}->{filter}, $F_MACH );

  $self->perchardata_set( scale => $o->{scale}, moneyframe => $mf->value );

}

# keep require happy
1;

#
# EOF
