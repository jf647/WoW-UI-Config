#
# $Id: Icons.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icons;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
has tmw => ( is => 'ro', isa => 'WoWUI::Module::TellMeWhen', weak_ref => 1 );
has char => ( is => 'ro', isa => 'WoWUI::Char', weak_ref => 1 );
has icons => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Module::TellMeWhen::Icon]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        icon_get => 'get',
        icon_set => 'set',
        icons_keys => 'keys',
        icons_values => 'values',
    },
);
CLASS->meta->make_immutable;

use Carp 'croak';

# constructor
sub BUILD
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    my $config = $self->tmw->modconfig( $self->char );

    for my $icon( keys %{ $config->{icons} } ) {
        unless( $config->{icons}->{$icon}->{type} ) {
            croak "no type defined for $icon";
        }
        my $type = 'WoWUI::Module::TellMeWhen::Icon::' . $config->{icons}->{$icon}->{type};
        $log->trace("building ", $config->{icons}->{$icon}->{type}, " object for '$icon'");
        $config->{icons}->{$icon}->{tag} = $icon;
        my $i = $type->new( tmw => $self->tmw, %{ $config->{icons}->{$icon} } );
        $self->icon_set( $icon, $i );
    }
    

}

# keep require happy
1;

#
# EOF
