 #
# $Id: Filter.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Filter;
use Moose;

use namespace::autoclean;

# set up class
has char => ( is => 'rw', isa => 'WoWUI::Char' );
has machine => ( is => 'rw', isa => 'WoWUI::Machine' );
has levelcap => ( is => 'rw', isa => 'Int', default => 85 );
has safe => ( is => 'rw', isa => 'Safe' );
has cache => (
    is => 'bare',
    isa => 'HashRef[Set::Scalar]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        flags_set => 'set',
        flags_get => 'get',
        flags_exists => 'exists',
    },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;
use Safe;

use WoWUI::Filter::Constants;
use WoWUI::Config;
use WoWUI::Machine;
use WoWUI::Util;

# constructor
sub BUILD
{

    my $self = shift;
    my $config = WoWUI::Config->instance->cfg;
    
    $self->levelcap( $config->{levelcap} );
    
    $self->safe( Safe->new );
    $self->safe->permit( qw|const bit_and bit_or| );

}

# check if we match a set of include / exclude flags
sub match
{

    my $self = shift;
    my $criteria = shift;
    my $using = shift;

    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'filter' );
    
    # level matching
    if( $self->char && exists $criteria->{level} ) {
        my($minl, $maxl);
        if( $criteria->{level} =~ m/^(\d+)?:(\d+)?$/ ) {
            $minl = defined $1 ? $1 : 1;
            $maxl = defined $2 ? $2 : $self->levelcap;
        }
        elsif( $criteria->{level} =~ m/^(\d+)$/ ) {
            ($minl, $maxl) = ($1, $self->levelcap);
        }
        else {
            croak "invalid level range '$criteria->{level}'";
        }
        $log->debug("filtering against level range $minl:$maxl");
        return unless( $self->char->level >= $minl && $self->char->level <= $maxl );
    }
    
    # addon filtering
    if( $self->char && exists $criteria->{addons} ) {
        my $req = Set::Scalar->new( @{ $criteria->{addons} } );
        $log->debug("required addons: $req");
        return unless( $req < $self->char->addons );
    }

    # build flags for include/exclude matching
    unless( $using ) {
        if( exists $criteria->{using} ) {
            $using = $self->safe->reval( $criteria->{using} );
        }
        else {
            $using = F_ALL;
        }
    }
    $log->trace("flag selection bits are $using");
    my $flags;
    if( $self->flags_exists($using) ) {
        $log->trace("reusing calculated flags");
        $flags = $self->flags_get($using);
    }
    else {
        $log->trace("building new flags");
        if( F_CALL | $using && ! defined $self->char ) {
            confess 'filter has no char but char flag match requested';
        }
        $flags = Set::Scalar->new;
        if( F_C0 & $using ) {
            $flags += $self->char->flags_get(0);
        }
        if( F_C1 & $using ) {
            $flags += $self->char->flags_get(1);
        }
        if( F_C2 & $using ) {
            $flags += $self->char->flags_get(2);
        }
        if( F_REALM & $using ) {
            $flags += $self->char->realm->flags;
        }
        if( F_PLAYER & $using ) {
            $flags += $self->char->player->flags;
        }
        if( F_MACH & $using ) {
            $flags += $self->machine->flags;
        }
        $self->flags_set($using, $flags);
    }
    $log->debug("matching against flagset: $flags");

    # check for an inclusion match
    my $include = $criteria->{include} || [ 'everyone' ];
    my $exclude = $criteria->{exclude};
    my $matched = 0;
    my $noexclude = 0;
    if( $include ) {
        for my $match( @{ $include } ) {
            my $clauses = Set::Scalar->new;
            if( $match =~ m/^all\((.+)\)$/ ) {
                $clauses->insert(split(/;/, $1));
                $log->trace("all include filter: $clauses");
                if( $clauses < $flags ) {
                    $matched = 1, last;
                }
            }
            elsif( $match =~ m/^noexall\((.+)\)$/ ) {
                $clauses->insert(split(/;/, $1));
                $log->trace("noexall include filter: $clauses");
                if( $clauses < $flags ) {
                    $matched = 1, $noexclude = 1, last;
                }
            }
            elsif( $match ) {
                $log->trace("single include filter: $match");
                if( $flags->contains( $match ) ) {
                    $matched = 1, last;
                }
            }
            else {
                croak "invalid clause in @$include";
            }
        }
    }

    # check for an exclusion
    if( $matched && 0 == $noexclude && $exclude ) {
        for my $match( @$exclude ) {
            my $clauses = Set::Scalar->new;
            if( $match =~ m/^all\((.+)\)$/ ) {
                $clauses->insert(split(/;/, $1));
                $log->trace("all exclude filter: $clauses");
                if( $clauses < $flags ) {
                    $matched = 0, last;
                }
            }
            elsif( $match ) {
                $log->trace("single exclude filter: $match");
                if( $flags->contains( $match ) ) {
                    $matched = 0, last;
                }
            }
            else {
                croak "invalid clause in @$exclude";
            }
        }
    }

    $log->trace("matched: $matched");
    return $matched;
    
}

# keep require happy
1;

#
# EOF
