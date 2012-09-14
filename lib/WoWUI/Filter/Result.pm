package WoWUI::Filter::Result;
use Moose;
use MooseX::StrictConstructor;

use strict;
use warnings;

has matched => ( is => 'rw', isa => 'Bool', default => 0 );
has value => ( is => 'rw' );

sub _matchedint {

    my $self = shift;

    return $self->matched ? 1 : 0;

}

use overload '""' => '_matchedint';

1;
