#
# $Id: Offensive.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Priority::Offensive;
use Moose::Role;

requires 'priority';

# the monks say this is the best worst way to augment construction via roles
# http://www.perlmonks.org/?node_id=837369
sub BUILD { }
after BUILD => sub {
    my $self = shift;
    $self->priority( $self->priority - 25 );
};

# keep require happy
1;

#
# EOF
