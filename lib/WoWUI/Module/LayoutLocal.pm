package WoWUI::Module::LayoutLocal;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

use WoWUI::Filter::Constants;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

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

    my $cfg = $self->modconfig($char);

    my @frames;
    for my $fname ( keys %{ $cfg->{frames} } ) {
        my $framecfg = $cfg->{frames}->{$fname};
        if ( my $value = $f->match( $framecfg->{filter} ) ) {
            $value->{value}->{name} = $fname;
            push @frames, $value->{value};
        }
    }

    $self->perchardata_set( frames => \@frames );

    return;

}

1;
