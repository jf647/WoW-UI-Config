#
# $Id: Icons.pm 5033 2011-06-12 17:06:06Z james $
#

package WoWUI::Module::TellMeWhen::Icons;
use MooseX::Singleton;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
has config => ( is => 'ro', isa => 'HashRef' );
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

use Carp 'croak';

# constructor
sub BUILD
{

    my $self = shift;

    my $log = WoWUI::Util->log;

    my $config = $self->config;

    for my $icon( keys %{ $config->{icons} } ) {
        unless( $config->{icons}->{$icon}->{type} ) {
            croak "no type defined for $icon";
        }
        my $type = 'WoWUI::Module::TellMeWhen::Icon::' . $config->{icons}->{$icon}->{type};
        $log->trace("building ", $config->{icons}->{$icon}->{type}, " object for '$icon'");
        $config->{icons}->{$icon}->{tag} = $icon;
        my $i = $type->new( $config->{icons}->{$icon} );
        $self->icon_set( $icon, $i );
    }
    

}

# keep require happy
1;

#
# EOF
