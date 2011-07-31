#
# $Id: Kong.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Kong;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
CLASS->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;

    $self->global( 1 );
    $self->perchar( 1 );
    
    return $self;

}

sub augment_data
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    my $config = $self->config;

    my $data;

    for my $realm( $self->player->realms ) {
        $log->debug("processing realm ", $realm->name);
        for my $char( $realm->chars ) {

            if( exists $config->{perchar_criteria} ) {
                next unless( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{perchar_criteria} ) );
            }
            $log->debug("processing character ", $char->name);

            # calculate profile name
            my $profilename = $char->rname;
            $profilename =~ tr/A-Z/a-z/;
            $profilename =~ s/\s/_/g;

            # build list of frames
            my @frames;
            my %groups;
            for my $frame( keys %{ $config->{frames} } ) {
                if( exists $config->{frames}->{$frame}->{criteria} ) {
                    if( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{frames}->{$frame}->{criteria} ) ) {
                        push @frames, $config->{frames}->{$frame};
                        if( my $group = $config->{frames}->{$frame}->{group} ) {
                            push @{ $groups{$group} }, $config->{frames}->{$frame}->{name};
                        }
                    }
                }
            }
            $data->{kong}->{$realm->name}->{$char->name} = {
                profilename => $profilename,
                frames => \@frames,
            };
            if( %groups ) {
                for my $group( keys %groups ) {
                    push @{ $data->{kong}->{$realm->name}->{$char->name}->{groups} }, { name => $group, frames => $groups{$group} };
                }
            }
        }
    }

    return $data;

}

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $profilename = $char->rname;
  $profilename =~ tr/A-Z/a-z/;
  $profilename =~ s/\s/_/g;

  return { realm => $char->realm->name, char => $char->name, profilename => $profilename };

}

# keep require happy
1;

#
# EOF
