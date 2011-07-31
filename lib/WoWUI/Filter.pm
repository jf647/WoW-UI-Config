 #
# $Id: Filter.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Filter;
use Moose;
use MooseX::StrictConstructor;

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
    my $filters = shift;
    my $using = shift;
    my $extra = shift;

    my $r = WoWUI::Filter::Result->new;

    if( 'ARRAY' eq ref $filters ) {
        for my $filter( @$filters ) {
            my $r2 = WoWUI::Filter::Result->new;
            if( $self->matchone( $r2, $filter, $using, $extra ) ) {
                $r = $r2;
                last if( exists $filter->{final} );
            }
        }
    }
    else {
        $self->matchone( $r, $filters, $using, $extra );
    }
    
    return $r;

}

sub matchone
{
    my $self = shift;
    my $r = shift;
    my $filter = shift;
    my $using = shift;
    my $extra = shift;
    
    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'filter' );
    
    # level matching
    if( $self->char && exists $filter->{level} ) {
        my($minl, $maxl);
        if( $filter->{level} =~ m/^(\d+)?:(\d+)?$/ ) {
            $minl = defined $1 ? $1 : 1;
            $maxl = defined $2 ? $2 : $self->levelcap;
        }
        elsif( $filter->{level} =~ m/^(\d+)$/ ) {
            ($minl, $maxl) = ($1, $self->levelcap);
        }
        else {
            croak "invalid level range '$filter->{level}'";
        }
        $log->debug("filtering against level range $minl:$maxl");
        return unless( $self->char->level >= $minl && $self->char->level <= $maxl );
    }
    
    # addon filtering
    if( $self->char && exists $filter->{addons} ) {
        my $req = Set::Scalar->new( @{ $filter->{addons} } );
        $log->debug("required addons: $req");
        return unless( $req < $self->char->addons );
    }

    # build flags for include/exclude matching
    unless( $using ) {
        if( exists $filter->{using} ) {
            $using = $self->safe->reval( $filter->{using} );
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
        if( (F_CALL|F_PLAYER|F_REALM)&$using && ! defined $self->char ) {
            confess 'filter has no char but char/realm/player flag match requested';
        }
        if( F_MACH&$using && ! defined $self->machine ) {
            confess 'filter has no machine but machine flag match requested';
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
            $flags += $self->char->realm->player->flags;
        }
        if( F_MACH & $using ) {
            $flags += $self->machine->flags;
        }
        $self->flags_set($using, $flags);
    }
    
    # if we have extra flags, clone before adding to avoid corrupting the cache
    if( $extra ) {
        my $newflags = $flags->clone;
        if( 'Set::Scalar' eq ref $extra ) {
            $newflags += $extra;
        }
        elsif( 'ARRAY' eq ref $extra ) {
            $newflags->insert( @$extra );
        }
        else {
            $newflags->insert( $extra );
        }
        $flags = $newflags;
    }
    $log->debug("matching against flagset: $flags");

    # check for an inclusion match
    my $include = $filter->{include} || [ 'everyone' ];
    my $exclude = $filter->{exclude};
    my $noexclude = 0;
    if( $include ) {
        for my $match( @{ $include } ) {
            my $clauses = Set::Scalar->new;
            if( $match =~ m/^all\((.+)\)$/ ) {
                $clauses->insert(split(/;/, $1));
                $log->trace("all include filter: $clauses");
                if( $clauses < $flags ) {
                    $r->matched( 1 );
                    last;
                }
            }
            elsif( $match =~ m/^noexall\((.+)\)$/ ) {
                $clauses->insert(split(/;/, $1));
                $log->trace("noexall include filter: $clauses");
                if( $clauses < $flags ) {
                    $r->matched( 1 );
                    $noexclude = 1;
                    last;
                }
            }
            elsif( $match ) {
                $log->trace("single include filter: $match");
                if( $flags->contains( $match ) ) {
                    $r->matched( 1 );
                    last;
                }
            }
            else {
                croak "invalid clause in @$include";
            }
        }
    }

    # check for an exclusion
    if( $r->matched && 0 == $noexclude && $exclude ) {
        for my $match( @$exclude ) {
            my $clauses = Set::Scalar->new;
            if( $match =~ m/^all\((.+)\)$/ ) {
                $clauses->insert(split(/;/, $1));
                $log->trace("all exclude filter: $clauses");
                if( $clauses < $flags ) {
                    $r->matched( 0 );
                    last;
                }
            }
            elsif( $match ) {
                $log->trace("single exclude filter: $match");
                if( $flags->contains( $match ) ) {
                    $r->matched( 0 );
                    last;
                }
            }
            else {
                croak "invalid clause in @$exclude";
            }
        }
    }

    # populate our value
    if( exists $filter->{value} ) {
        $r->value( $filter->{value} );
    }

    $log->trace("matched: $r");
    return $r;
    
}

package WoWUI::Filter::Result;
use Moose;
use MooseX::StrictConstructor;

has matched => ( is => 'rw', isa => 'Bool', default => 0 );
has value => ( is => 'rw' );

sub _matchedint
{
    $_[0]->matched ? 1 : 0;
}
use overload
    '""' => '_matchedint';

# keep require happy
1;

#
# EOF
