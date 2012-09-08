package WoWUI::Module::TellMeWhen::RawLua;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

with 'WoWUI::Module::TellMeWhen::Dumpable';
has luastr => ( is => 'rw', isa => 'Str', required => 1 );

sub lua
{

    my $self = shift;
    return $self->luastr;

}

sub augment_lua { "" }

1;
