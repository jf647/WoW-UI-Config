#
# $Id$
#

package WoWUI::Modules;
use MooseX::Singleton;
use MooseX::StrictConstructor;

use strict;
use warnings;

use Carp 'croak';
use namespace::autoclean;

# set up class
has modules => (
    is      => 'bare',
    isa     => 'HashRef[WoWUI::Module::Base]',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        module_get    => 'get',
        module_set    => 'set',
        module_names  => 'keys',
        module_exists => 'exists',
        modules       => 'values',
    },
);
has processed => (
    is      => 'bare',
    isa     => 'HashRef[Str]',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        processed_set    => 'set',
        processed_exists => 'exists',
    },
);

before module_get => sub {

    my $self    = shift;
    my $modname = shift;

    unless ( $self->module_exists($modname) ) {
        eval "require $modname";
        if ($@) {
            croak "can't load $modname: $@";
        }
        my $module = $modname->new;
        $self->module_set( $modname, $module );
    }

};

# keep require happy
1;

#
# EOF
