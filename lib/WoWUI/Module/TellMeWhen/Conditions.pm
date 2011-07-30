#
# $Id: Conditions.pm 5023 2011-06-02 15:54:10Z james $
#

package WoWUI::Module::TellMeWhen::Conditions;
use MooseX::Singleton;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
has conditions => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Module::TellMeWhen::Condition]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        cond_get => 'get',
        cond_set => 'set',
        cond_keys => 'keys',
        cond_values => 'values',
    },
);
has anoncount => (
    is => 'bare',
    isa => 'Int',
    traits => ['Counter'],
    default => 0,
    handles => {
        _nextanoncount => 'inc',
    },
);
# causes problems - build is never called with 0.27 of MooseX::Singleton
#__PACKAGE__->meta->make_immutable;

# constructor
sub BUILD
{

    my $self = shift;
    my $a = shift;

    for my $cname( keys %{ $a->{config}->{conditions} } ) {
        $a->{config}->{conditions}->{$cname}->{tag} = $cname;
        unless( exists $a->{config}->{conditions}->{$cname}->{Name} ) {
            $a->{config}->{conditions}->{$cname}->{Name} = $cname;
        }
        my $c = WoWUI::Module::TellMeWhen::Condition->new(
            %{ $a->{config}->{conditions}->{$cname} }
        );
        $self->cond_set( $cname, $c );
    }

}

# get the next anonymous name
sub nextanon
{

    return '_anon_' . $_[0]->_nextanoncount;

}

# keep require happy
1;

#
# EOF
