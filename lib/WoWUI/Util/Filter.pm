#
# $Id: Filter.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Util::Filter;

use Carp 'croak';

use Set::Scalar;

use WoWUI::Util 'log';

# check if we match a set of include / exclude flags
sub matches
{

    my $origflags = shift;
    my $char = shift;
    my $thing = shift;
    my $extra = shift;

    my $config = WoWUI::Config->instance->cfg;
    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'filter' );

    # level filtering
    if( $char && exists $thing->{level} ) {
        my($minl, $maxl);
        if( $thing->{level} =~ m/^(\d+)?:(\d+)?$/ ) {
            $minl = defined $1 ? $1 : 1;
            $maxl = defined $2 ? $2 : $config->{levelcap};
        }
        elsif( $thing->{level} =~ m/^(\d+)$/ ) {
            ($minl, $maxl) = ($1, $config->{levelcap});
        }
        else {
            croak "invalid level range '$thing->{level}'";
        }
        $log->debug("filtering against level range $minl:$maxl");
        return if( $char->level < $minl || $char->level > $maxl );
    }
    
    # addon filtering
    if( $char && exists $thing->{addons} ) {
        my $req = Set::Scalar->new( @{ $thing->{addons} } );
        $log->trace("required addons: $req");
        unless( $req < $char->addons ) {
            $log->debug("required addons not activated");
            return;
        }
    }

    # check for an inclusion match
    my $include = $thing->{include};
    $include ||= [ 'everyone' ];
    my $exclude = $thing->{exclude};
    my $flags = $origflags->clone;
    if( 'Set::Scalar' eq ref $extra ) {
        $flags += $extra;
    }
    elsif( 'ARRAY' eq ref $extra ) {
        $flags->insert( @$extra );
    }
    elsif( $extra ) {
        $flags->insert( $extra );
    }
    $log->trace("flags: $flags");
    my $matched = 0;
    my $noexclude = 0;
    if( $include ) {
        for my $match( @{ $include } ) {
            my $clauses = Set::Scalar->new;
            if( $match =~ m|^all\((.+)\)$| ) {
                $clauses->insert(split(/;/, $1));
                $log->trace("all include filter: $clauses");
                if( $clauses < $flags ) {
                    $matched = 1, last;
                }
            }
            elsif( $match =~ m|^noexall\((.+)\)$| ) {
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


sub check_filter_groups
{

    my $groups = shift;
    my $things = shift;
    my $thingkey = shift;

    my $log = WoWUI::Util->log();

    my $all_things = Set::Scalar->new( keys %$things );
    my $part_of_group = Set::Scalar->new;

    for my $group( keys %$groups ) {
        for my $thing( @{ $groups->{$group}->{$thingkey} } ) {
            unless( $all_things->contains( $thing ) ) {
                croak "filter check failed: element $thing not found";
            }
            $part_of_group->insert( $thing );
        }
    }
    
    my $condonly_things = Set::Scalar->new;
    my $flags = Set::Scalar->new( 'conditiononly' );
    for my $thing( keys %$things ) {
        if( exists $things->{$thing}->{nofiltergroup} ) {
            $condonly_things->insert( $thing );
        }
    }
    my $not_part_of_group = $all_things - $part_of_group - $condonly_things;
    if( $not_part_of_group ) {
        croak "filter check failed; not part of group: ", join(', ', $not_part_of_group->members);
    }

}

sub filter_groups
{

    my $flags = shift;
    my $groups = shift;
    my $thingkey = shift;

    my @candidates;
    for my $group( keys %$groups ) {
        if( WoWUI::Util::Filter::matches( $flags, undef, $groups->{$group} ) ) {
            push @candidates, @{ $groups->{$group}->{$thingkey} };
        }
    }
    
    return wantarray ? @candidates : \@candidates;

}


# keep require happy
1;

#
# EOF
