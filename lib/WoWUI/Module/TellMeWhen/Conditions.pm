#
# $Id: Conditions.pm 5023 2011-06-02 15:54:10Z james $
#

package WoWUI::Module::TellMeWhen::Conditions;
use MooseX::Singleton;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
has config => ( is => 'ro', isa => 'HashRef' );
has conditions => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Module::TellMeWhen::Condition]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        get => 'get',
        set => 'set',
        names => 'keys',
        conditions => 'values',
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

    for my $cname( keys %{ $self->config->{conditions} } ) {
        $self->config->{conditions}->{$cname}->{tag} = $cname;
        unless( exists $self->config->{conditions}->{$cname}->{Name} ) {
            $self->config->{conditions}->{$cname}->{Name} = $cname;
        }
        my $c = WoWUI::Module::TellMeWhen::Condition->new(
            %{ $self->config->{conditions}->{$cname} }
        );
        $self->set( $cname, $c );
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
