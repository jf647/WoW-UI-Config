#
# $Id: SpellName.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::Module::TellMeWhen::Icon::SpellName;
use Moose::Role;

# the monks say this is the best worst way to augment construction via roles
# http://www.perlmonks.org/?node_id=837369
sub BUILD {}
after BUILD => sub {

    my $self = shift;
    my $icfg = shift;
    
    # prefer spellid over spell over the tag
    $self->Name( $icfg->{spellid} || $icfg->{spell} || $icfg->{tag} );
    
    return $self;

};

# keep require happy
1;

#
# EOF
