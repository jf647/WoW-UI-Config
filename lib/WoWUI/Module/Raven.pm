#
# $Id: Raven.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Raven;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
has profileset => (
    is => 'rw',
    isa => 'WoWUI::ProfileSet',
    default => sub { WoWUI::ProfileSet->new },
);
CLASS->meta->make_immutable;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{
    
    my $self = shift;
    
    $self->global( 1 );
    $self->globalpc( 1 );
    $self->globaldata_set( chars => {} );
    
    return $self;
    
}

sub augment_global
{

    my $self = shift;

    $self->globaldata_set( pset => $self->profileset );

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;

    my $config = $self->modconfig( $char );
    my $o = $self->modoptions( $char );

    my $profile = {
        debuffs => $o->{debuffs},
        shortbuffs => $o->{shortbuffs},
        longbuffs => $o->{longbuffs},
        ic => $o->{ic},
    };
    if( exists $config->{icbuffs}->{$char->class} ) {
         $profile->{icbuffs} = $config->{icbuffs}->{$char->class};
    }
    my $pname = $self->profileset->store( $profile, $char->class );
    $self->globaldata_get( 'chars' )->{$char->dname} = $pname;

}

# keep require happy
1;

#
# EOF
