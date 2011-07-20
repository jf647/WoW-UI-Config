#
# $Id: FilterGroup.pm 5025 2011-06-03 11:04:23Z james $
#

package WoWUI::FilterGroup;
use Moose;

use namespace::autoclean;

# set up class
has name => ( is => 'rw', isa => 'Str', required => 1 );
has filter => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has members => ( is => 'rw', isa => 'Set::Scalar' );
__PACKAGE__->meta->make_immutable;

use Set::Scalar;

# constructor
sub BUILD
{

    my $self = shift;
    my $config = $_[0]->{config};
    
    if( exists $config->{filter} ) {
        $self->filter( $config->{filter} );
    }
    $self->members( Set::Scalar->new( @{ $config->{members} } ) );
    
}

# keep require happy
1;

#
# EOF

