
# $Id: Digits.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Module::Digits;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
augment data => \&augment_data;
__PACKAGE__->meta->make_immutable;

use Clone 'clone';
use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'digits', global => 1, perchar => 0 };
}

sub augment_data
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    my $config = $self->config;
    my $o = WoWUI::Machine->instance->modoption_get('digits');

    my $data;
      
    # per-char settings
    for my $realm( WoWUI::Profile->instance->realms_values ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars_values ) {

            if( exists $config->{perchar_criteria} ) {
                next unless( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{perchar_criteria} ) );
            }

            # frames enabled
            my %ft_enabled;
            for my $f( keys %{ $config->{frames} } ) {
                my $fn = $config->{frames}->{$f}->{name};
                $data->{realms}->{$realm->name}->{$char->name}->{frames}->{$fn} ||= {
                    enabled => 0,
                    percent => 0,
                    ooc => 0
                };
                if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{frames}->{$f} ) ) {
                    if( exists $ft_enabled{$fn} ) {
                        croak "double match on $fn for ", $char->name, " of ", $realm->name, ": $ft_enabled{$fn} before $f";
                    }
                    else {
                        $ft_enabled{$fn} = $f;
                    }
                    $data->{realms}->{$realm->name}->{$char->name}->{frames}->{$fn} = {
                        enabled => 1,
                        percent => $config->{frames}->{$f}->{percent},
                        ooc => $config->{frames}->{$f}->{ooc},
                    }
                }
            }

            # power types
            for my $p( keys %{ $config->{powertypes} } ) {
                if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{powertypes}->{$p} ) ) {
                    $data->{realms}->{$realm->name}->{$char->name}->{$p} = 1;
                }
                else {
                    $data->{realms}->{$realm->name}->{$char->name}->{$p} = 0;
                }
            }

        }
    }

    if( %{ $data->{realms} } ) {
        $data->{font} = $o->{font};
        $data->{anchor} = $o->{anchor};
        $data->{powertypes} = $config->{powertypes};
    }

    return $data;

}

# keep require happy
1;

#
# EOF
