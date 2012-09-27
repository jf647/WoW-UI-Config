package WoWUI::Module::NADTQuestShare;
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

    my $master = 0;
    my $slave  = 0;

    if (
        $f->match(
            { include => ['all(dualbox;machine:type:primary)'] },
            F_C0 | F_MACH
        )
      )
    {
        $master = 1;
    }
    elsif (
        $f->match(
            { include => ['all(dualbox;machine:type:secondary)'] },
            F_C0 | F_MACH
        )
      )
    {
        $slave = 1;
    }

    $self->perchardata_set( master => $master, slave => $slave );

    return;

}

1;
