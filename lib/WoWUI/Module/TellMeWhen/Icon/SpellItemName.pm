#
# $Id: SpellName.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Module::TellMeWhen::Icon::SpellItemName;
use Moose::Role;

# the monks say this is the best worst way to augment construction via roles
# http://www.perlmonks.org/?node_id=837369
has spell => ( is => 'ro', isa => 'Str' );
has spellid => ( is => 'ro', isa => 'Int' );
has item => ( is => 'ro', isa => 'Str' );
sub BUILD {}
after BUILD => sub {

    my $self = shift;
    
    # prefer spellid over spell over item
    for my $attr( qw|spellid spell item| ) {
      if( $self->$attr ) {
        $self->Name( $self->$attr );
        last;
      }
    }
    
    return $self;

};

# keep require happy
1;

#
# EOF
