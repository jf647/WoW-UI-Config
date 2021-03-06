#
# $Id: FilterGroups.pm 5027 2011-06-04 13:49:57Z james $
#

package WoWUI::FilterGroups;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
has [qw|filtergroups things|] => ( is => 'ro', isa => 'HashRef' );
has groups => (
    is      => 'bare',
    isa     => 'HashRef[WoWUI::FilterGroup]',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        group_set     => 'set',
        group_get     => 'get',
        groups_names  => 'keys',
        groups_values => 'values',
    },
);
CLASS->meta->make_immutable;

use WoWUI::FilterGroup;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Util;

# build filtergroups from a config block
sub BUILDARGS
{

    my $class = shift;
    return { filtergroups => shift, things => shift };

}

sub BUILD
{

    my $self = shift;
    for my $fgname ( keys %{ $self->filtergroups } ) {
        my $fg = WoWUI::FilterGroup->new(
            name   => $fgname,
            config => $self->filtergroups->{$fgname},
        );
        $self->group_set( $fgname, $fg );
    }

    $self->validate( $self->things );

    return;

}

# validate all the groups
sub validate
{

    my $self = shift;
    my $all  = shift;

    my $log = WoWUI::Util->logger();

    my $all_set       = Set::Scalar->new( keys %$all );
    my $part_of_group = Set::Scalar->new;

    # walk over each group
    for my $fg ( $self->groups_values ) {

        # are the members of things group in the list of all things?
        unless ( $fg->members->is_proper_subset($all_set) ) {
            croak $fg->name, " contains members which don't exist: ",
              $fg->members - $all_set;
        }
        $part_of_group += $fg->members;
    }

    # check that every thing is in a group unless explicitly excluded
    my $ok_not_in_group = Set::Scalar->new;
    for my $thing ( $all_set->members ) {
        if ( exists $all->{$thing}->{no_filter_group_ok} ) {
            $ok_not_in_group->insert($thing);
        }
    }
    my $not_part_of_group = $all_set - $part_of_group - $ok_not_in_group;
    if ( $not_part_of_group->size ) {
        croak "filter check failed: $not_part_of_group are not in any group";
    }

}

# get candidates based on a filter
sub candidates
{

    my $self  = shift;
    my $f     = shift;
    my $using = shift;

    my $log = WoWUI::Util->logger( stacksup => 1, prefix => 'filtergroups' );

    my $candidates = Set::Scalar->new;

    for my $fg ( $self->groups_values ) {
        $log->debug( "considering filter group ", $fg->name );
        if ( $f->match( $fg->filter, $using ) ) {
            $log->debug("filter group matches");
            $candidates += $fg->members;
        }
    }

    return $candidates;

}

# keep require happy
1;

#
# EOF
