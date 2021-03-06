#
# $Id: FilterGroup.pm 5025 2011-06-03 11:04:23Z james $
#

package WoWUI::FilterGroup;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
has config  => ( is => 'ro', isa => 'HashRef' );
has name    => ( is => 'rw', isa => 'Str', required => 1 );
has filter  => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has members => ( is => 'rw', isa => 'Set::Scalar' );
CLASS->meta->make_immutable;

use Set::Scalar;

# constructor
sub BUILD
{

    my $self = shift;

    if ( exists $self->config->{filter} ) {
        $self->filter( $self->config->{filter} );
    }
    $self->members( Set::Scalar->new( @{ $self->config->{members} } ) );

    return;

}

# keep require happy
1;

#
# EOF

