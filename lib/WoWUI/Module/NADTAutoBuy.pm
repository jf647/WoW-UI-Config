package WoWUI::Module::NADTAutoBuy;
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
use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;

    $self->perchar(1);

    return $self;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my $config = $self->modconfig($char)->{nadtautobuy};
    my $o      = $self->modoptions($char);

    my %profile;
    for my $ic ( keys %{ $config->{itemclasses} } ) {
        my $filter = $config->{itemclasses}->{$ic}->{filter};
        if ( my $r = $f->match($filter) ) {
            my $quantity = 0;
            if ( defined $r->value ) {
                $quantity = $r->value;
            }
            else {
                croak "match but not value for ", $f->char->name,
                  "; itemclass $ic";
            }
            my @itemids;
            for my $item ( @{ $config->{itemclasses}->{$ic}->{members} } ) {
                unless ( exists $config->{items}->{$item} ) {
                    croak "undefined item '$item' in itemclass $ic";
                }
                my $ifilter = $config->{items}->{$item}->{filter};
                if ( my $r = $f->match($ifilter) ) {
                    if( defined $config->{items}->{$item}->{itemid} ) {
                        push @itemids, $config->{items}->{$item}->{itemid};
                    }
                    else {
                        croak "no/undefined itemid for $item";
                    }
                }
            }
            if (@itemids) {
                $profile{$ic} = { quantity => $quantity, items => \@itemids };
            }
        }
    }
    
    $self->perchardata_set( autobuy => \%profile );

    return;

}

1;
