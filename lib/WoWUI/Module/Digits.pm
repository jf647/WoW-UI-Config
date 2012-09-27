
# $Id: Digits.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Module::Digits;
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

    $self->global(1);
    $self->globalpc(1);

    return $self;

}

sub augment_global
{

    my $self = shift;

    my $config = $self->modconfig;
    my $o      = $self->modoptions;

    if ( $self->has_globaldata ) {
        $self->globaldata_set( font       => $o->{font} );
        $self->globaldata_set( anchor     => $o->{anchor} );
        $self->globaldata_set( powertypes => $config->{powertypes} );
    }

    return $self;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my $log = WoWUI::Util->logger;

    my $config = $self->modconfig($char);
    my $o      = $self->modoptions;

    # frames enabled
    my %ft_enabled;
    for my $frame ( keys %{ $config->{frames} } ) {
        my $fn = $config->{frames}->{$frame}->{name};
        $self->globaldata->{realms}->{ $f->char->realm->name }
          ->{ $f->char->name }->{frames}->{$fn} ||= {
            enabled => 0,
            percent => 0,
            ooc     => 0
          };
        if ( $f->match( $config->{frames}->{$frame}->{filter} ) ) {
            if ( exists $ft_enabled{$fn} ) {
                croak "double match on $fn for ", $char->rname,
                  ": $ft_enabled{$fn} before $frame";
            }
            else {
                $ft_enabled{$fn} = $frame;
            }
            $self->globaldata->{realms}->{ $f->char->realm->name }
              ->{ $f->char->name }->{frames}->{$fn} = {
                enabled => 1,
                percent => $config->{frames}->{$frame}->{percent},
                ooc     => $config->{frames}->{$frame}->{ooc},
              };
        }
    }

    # power types
    for my $p ( keys %{ $config->{powertypes} } ) {
        if ( $f->match( $config->{powertypes}->{$p}->{filter} ) ) {
            $self->globaldata->{realms}->{ $f->char->realm->name }
              ->{ $f->char->name }->{$p} = 1;
        }
        else {
            $self->globaldata->{realms}->{ $f->char->realm->name }
              ->{ $f->char->name }->{$p} = 0;
        }
    }

    return $self;

}

# keep require happy
1;

#
# EOF
