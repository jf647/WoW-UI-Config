#
# $Id: SpellName.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Usable;
use Moose::Role;

# the monks say this is the best worst way to augment construction via roles
# http://www.perlmonks.org/?node_id=837369
has [ qw|usable unusable always| ] => ( is => 'ro', isa => 'Bool' );
sub BUILD {}
after BUILD => sub {

    my $self = shift;
    
    # usable / unusable
    if( $self->unusable ) {
        $self->ShowWhen( 'unalpha' );
        $self->UnAlpha( 0.5 );
    }
    elsif( $self->always ) {
        $self->ShowWhen( 'always' );
        $self->UnAlpha( 0.5 );
    }

    return $self;

};

# keep require happy
1;

#
# EOF
