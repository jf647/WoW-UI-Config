#
# $Id: Runes.pm 5015 2011-05-30 11:39:08Z james $
#

package WoWUI::Module::TellMeWhen::Condition::Runes;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
with 'WoWUI::Module::TellMeWhen::Dumpable' => { -excludes => 'lua' };
has runes => (
    is => 'rw',
    isa => 'ArrayRef[Maybe[Bool]]',
    default => sub { [] },
);
__PACKAGE__->meta->make_immutable;

use WoWUI::LuaDumper;

# custom dumper - we only consume the role to let LuaDumper dispatch to us
sub lua
{

    my $self = shift;

    return join(', ', map {
        defined $_ ? $_ ? 'true' : 'false' : 'nil'
    } @{ $self->runes } );

}

sub augment_lua {}

# keep require happy
1;

#
# EOF
