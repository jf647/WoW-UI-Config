#
# $Id: Basic.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Basic;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
augment data => \&augment_data;
augment chardata => \&augment_chardata;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

sub augment_data
{

    my $self = shift;

    my $data = inner();
    return $data || {};

}

sub augment_chardata
{

    my $self = shift;
    my $char = shift;
    
    my $data = inner();
    return $data || { realm => $char->realm->name, char => $char->name };

}

# keep require happy
1;

#
# EOF
