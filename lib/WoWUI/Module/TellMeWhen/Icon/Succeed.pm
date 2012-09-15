#
# $Id: SpellName.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Succeed;
use Moose::Role;

# the monks say this is the best worst way to augment construction via roles
# http://www.perlmonks.org/?node_id=837369
has [ qw|succeed fail always| ] => ( is => 'ro', isa => 'Bool' );
sub BUILD {}
after BUILD => sub {

    my $self = shift;
    
    # succeed / fail
    if( $self->fail ) {
        $self->ShowWhen( 0x1 );
        $self->UnAlpha( 0.5 );
    }
    elsif( $self->always ) {
        $self->ShowWhen( 0x3 );
        $self->UnAlpha( 0.5 );
    }

    return $self;

};

# keep require happy
1;

#
# EOF
