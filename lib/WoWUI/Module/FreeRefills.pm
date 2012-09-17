#
# $Id: FreeRefills.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::FreeRefills;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->globalpc( 1 );
    
    return $self;
    
}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $log = WoWUI::Util->logger;
    my $config = $self->modconfig( $char );

    my %items;
    for my $fr( keys %{ $config->{freerefills} } ) {
        my $frdata = $config->{freerefills}->{$fr};
        if( $f->match( $frdata->{filter} ) ) {
            if( exists $items{$frdata->{itemid}} ) {
                croak "$fr has been picked twice for ", $char->realm->name, "/", $char->name;
            }
            $items{$frdata->{itemid}} = clone $frdata;
            unless( exists $frdata->{name} ) {
                $items{$frdata->{itemid}}->{name} = $fr;
            }
        }
    }
    if( %items ) {
        $self->globaldata->{freerefills}->{$char->realm->name}->{$char->name} = [ values %items ];
    }

}

# keep require happy
1;

#
# EOF
