#
# $Id: SpellName.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Present;
use Moose::Role;

# the monks say this is the best worst way to augment construction via roles
# http://www.perlmonks.org/?node_id=837369
sub BUILD {}
after BUILD => sub {

    my $self = shift;
    my $icfg = shift;
    
    # present / missing
    if( exists $icfg->{missing} ) {
        $self->ShowWhen('unalpha');
        $self->UnAlpha( 0.5 );
    }
    elsif( exists $icfg->{always} ) {
        $self->ShowWhen( 'always' );
        $self->UnAlpha( 0.5 );
    }

    return $self;

};

# keep require happy
1;

#
# EOF
