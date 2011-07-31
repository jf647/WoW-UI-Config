#
# $Id: Icon.pm 5001 2011-05-27 12:13:58Z james $
#

package WoWUI::Module::TellMeWhen::Condition::Icon;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Condition';
has '+Type' => ( default => 'ICON' );
CLASS->meta->make_immutable;

# constructor
sub BUILD
{

    my $self = shift;

    if( $self->Icon =~ m/^!(.+)$/ ) {
        $self->Icon( $1 );
        $self->Level( 1 );
    }
    
    return $self;
    
}

# keep require happy
1;

#
# EOF
