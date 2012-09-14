#
# $Id: Filter.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Filter;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
has char     => ( is => 'rw', isa => 'WoWUI::Char' );
has machine  => ( is => 'rw', isa => 'WoWUI::Machine' );
has levelcap => ( is => 'rw', isa => 'Int', default => 85 );
has safe     => ( is => 'rw', isa => 'Safe' );
has cache => (
    is      => 'bare',
    isa     => 'HashRef[Set::Scalar]',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        flags_set    => 'set',
        flags_get    => 'get',
        flags_exists => 'exists',
    },
);
CLASS->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;
use Safe;

use WoWUI::Filter::Constants;
use WoWUI::Filter::Result;
use WoWUI::Config;
use WoWUI::Machine;
use WoWUI::Util;

# constructor
sub BUILD {

    my $self   = shift;
    my $config = WoWUI::Config->instance->cfg;

    $self->levelcap( $config->{levelcap} );

    $self->safe( Safe->new );
    $self->safe->permit(qw|const bit_and bit_or|);

    return;

}

# check if we match a set of include / exclude flags
sub match {

    my $self    = shift;
    my $filters = shift;
    my $using   = shift;
    my $extra   = shift;

    my $r = WoWUI::Filter::Result->new;

    if ( 'ARRAY' eq ref $filters ) {
        for my $filter (@$filters) {
            my $r2 = WoWUI::Filter::Result->new;
            if ( $self->matchone( $r2, $filter, $using, $extra ) ) {
                $r = $r2;
                last if ( exists $filter->{final} );
            }
        }
    }
    else {
        if ( exists $filters->{filter} ) {
            croak "bad single filter passed (one level too high?)";
        }
        $self->matchone( $r, $filters, $using, $extra );
    }

    return $r;

}

sub matchone {
    my $self   = shift;
    my $r      = shift;
    my $filter = shift;
    my $using  = shift;
    my $extra  = shift;

    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'filter' );

    # level matching
    return unless ( $self->match_level );

    # addon filtering
    return unless ($self_match_addons);

    # build flags for include/exclude matching
    unless ($using) {
        if ( exists $filter->{using} ) {
            $using = $self->safe->reval( $filter->{using} );
        }
        else {
            $using = $F_ALL;
        }
    }
    $log->trace("flag selection bits are $using");
    my $flags;
    if ( $self->flags_exists($using) ) {
        $log->trace("reusing calculated flags");
        $flags = $self->flags_get($using);
    }
    else {
        $log->trace("building new flags");
        $flags = $self->build_flags($using);
        $self->flags_set( $using, $flags );
    }

    # if we have extra flags, clone before adding to avoid corrupting the cache
    if ($extra) {
        my $newflags = $flags->clone;
        if ( 'Set::Scalar' eq ref $extra ) {
            $newflags += $extra;
        }
        elsif ( 'ARRAY' eq ref $extra ) {
            $newflags->insert(@$extra);
        }
        else {
            $newflags->insert($extra);
        }
        $flags = $newflags;
    }
    $log->debug("matching against flagset: $flags");

    # check for an inclusion match
    $self->match_inclusion( $r, $filter, $using, $extra );

    # check for an exclusion
    $self->match_exclusion( $r, $filter, $using, $extra );

    # populate our value
    if ( $r->matched && exists $filter->{value} ) {
        $r->value( $filter->{value} );
    }

    $log->trace("matched: $r");
    return $r;

}

sub match_addons {

    my $self   = shift;
    my $filter = shift;

    if ( $self->char && exists $filter->{addons} ) {
        my $req = Set::Scalar->new( @{ $filter->{addons} } );
        $log->debug("required addons: $req");
        return unless ( $req->is_proper_subset( $self->char->addons ) );
    }

    return 1;

}

sub match_level {

    my $self   = shift;
    my $filter = shift;

    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'filter' );

    if ( $self->char && exists $filter->{level} ) {
        my ( $minl, $maxl );
        if ( $filter->{level} =~ m/^(\d+)?:(\d+)?$/x ) {
            $minl = defined $1 ? $1 : 1;
            $maxl = defined $2 ? $2 : $self->levelcap;
        }
        elsif ( $filter->{level} =~ m/^(\d+)$/x ) {
            ( $minl, $maxl ) = ( $1, $self->levelcap );
        }
        else {
            croak "invalid level range '$filter->{level}'";
        }
        $log->debug("filtering against level range $minl:$maxl");
        return if ( $self->char->level < $minl || $self->char->level > $maxl );
    }

    return 1;

}

sub build_flags {

    my $self  = shift;
    my $using = shift;

    if ( ( $F_CALL | $F_PLAYER | $F_REALM ) & $using && !defined $self->char ) {
        confess 'filter has no char but char/realm/player flag match requested';
    }
    if ( $F_MACH & $using && !defined $self->machine ) {
        confess 'filter has no machine but machine flag match requested';
    }
    $flags = Set::Scalar->new;
    if ( $F_C0 & $using ) {
        $flags += $self->char->flags_get(0);
    }
    if ( $F_C1 & $using ) {
        $flags += $self->char->flags_get(1);
    }
    if ( $F_C2 & $using ) {
        $flags += $self->char->flags_get(2);
    }
    if ( $F_REALM & $using ) {
        $flags += $self->char->realm->flags;
    }
    if ( $F_PLAYER & $using ) {
        $flags += $self->char->realm->player->flags;
    }
    if ( $F_MACH & $using ) {
        $flags += $self->machine->flags;
    }

    return $flags;

}

sub match_inclusion {

    my $r      = shift;
    my $filter = shift;
    my $using  = shift;
    my $extra  = shift;

    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'filter' );

    my $noexclude = 0;
    if ( exists $filter->{include} ) {
        my $include = $filter->{include};
        for my $match ( @{$include} ) {
            my $clauses = Set::Scalar->new;
            if ( $match =~ m/^all\((.+)\)$/x ) {
                $clauses->insert( split( /;/x, $1 ) );
                $log->trace("all include filter: $clauses");
                if ( $clauses < $flags ) {
                    $r->matched(1);
                    last;
                }
            }
            elsif ( $match =~ m/^noexall\((.+)\)$/x ) {
                $clauses->insert( split( /;/x, $1 ) );
                $log->trace("noexall include filter: $clauses");
                if ( $clauses < $flags ) {
                    $r->matched(1);
                    $noexclude = 1;
                    last;
                }
            }
            elsif ($match) {
                $log->trace("single include filter: $match");
                if ( $flags->contains($match) ) {
                    $r->matched(1);
                    last;
                }
            }
            else {
                croak "invalid clause in @$include";
            }
        }
    }
    else {
        $log->trace("no include block; auto-matching");
        $r->matched(1);
    }

    return;

}

sub match_exclusion {

    my $r      = shift;
    my $filter = shift;
    my $using  = shift;
    my $extra  = shift;

    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'filter' );

    if ( $r->matched && 0 == $noexclude && exists $filter->{exclude} ) {
        my $exclude = $filter->{exclude};
        for my $match (@$exclude) {
            my $clauses = Set::Scalar->new;
            if ( $match =~ m/^all\((.+)\)$/x ) {
                $clauses->insert( split( /;/x, $1 ) );
                $log->trace("all exclude filter: $clauses");
                if ( $clauses < $flags ) {
                    $r->matched(0);
                    last;
                }
            }
            elsif ($match) {
                $log->trace("single exclude filter: $match");
                if ( $flags->contains($match) ) {
                    $r->matched(0);
                    last;
                }
            }
            else {
                croak "invalid clause in @$exclude";
            }
        }
    }

    return;

}

# keep require happy
1;

#
# EOF
