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
use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;

    $self->globalpc( 1 );
    $self->perchar( 1 );
    
    return $self;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $log = WoWUI::Util->log;
    my $config = $self->modconfig( $char );

    # build list of frames
    my @frames;
    my %groups;
    for my $frame( keys %{ $config->{frames} } ) {
        if( exists $config->{frames}->{$frame}->{filter} ) {
            if( $f->match( $config->{frames}->{$frame}->{filter}, F_ALL ) ) {
                push @frames, $config->{frames}->{$frame};
                if( my $group = $config->{frames}->{$frame}->{group} ) {
                    push @{ $groups{$group} }, $config->{frames}->{$frame}->{name};
                }
            }
        }
    }
    $self->globaldata->{kong}->{$char->realm->name}->{$char->name} = {
        profilename => $self->profilename( $char ),
        frames => \@frames,
    };
    if( %groups ) {
        for my $group( keys %groups ) {
            push @{ $self->globaldata->{kong}->{$char->realm->name}->{$char->name}->{groups} },
                { name => $group, frames => $groups{$group} };
        }
    }

}

sub augment_perchar
{

  my $self = shift;
  my $char = shift;
  my $f = shift;

  $self->perchardata_set( profilename => $self->profilename( $char ) );

}

sub profilename
{

    my $self = shift;
    my $char = shift;
    
    my $profilename = $char->rname;
    $profilename =~ tr/A-Z/a-z/;
    $profilename =~ s/\s/_/g;
    
    return $profilename;

}

# keep require happy
1;

#
# EOF
