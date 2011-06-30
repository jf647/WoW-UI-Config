#
# $Id: RobBossMods.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::RobBossMods;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Basic';
augment data => \&augment_data;
__PACKAGE__->meta->make_immutable;

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'robbossmods', global => 1, perchar => 0 };
}

sub augment_data
{

    my $self = shift;
    my $data = shift;
    
    my $config = $self->config;
    
    for my $boss( keys %{ $config->{strategies} } ) {
        my $s =  $config->{strategies}->{$boss};
        $s->{name} = $boss;
        chomp $s->{strategy};
        push @{ $data->{strats} }, $s;
    }
    
    return $data;

}

# keep require happy
1;

#
# EOF
