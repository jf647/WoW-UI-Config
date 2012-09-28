#
# $Id: Addons.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Addons;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

# set up class
extends 'WoWUI::Module::Base';
has 'named_sets' => (
    traits  => ['Hash'],
    is      => 'bare',
    isa     => 'HashRef[Set::Scalar]',
    default => sub { {} },
    handles => {
        named_get    => 'get',
        named_set    => 'set',
        named_list   => 'keys',
        named_values => 'values',
        named_count  => 'count',
    },
);
has 'class_sets' => (
    traits  => ['Hash'],
    is      => 'bare',
    isa     => 'HashRef[Set::Scalar]',
    default => sub { {} },
    handles => {
        class_get    => 'get',
        class_set    => 'set',
        class_list   => 'keys',
        class_values => 'values',
        class_count  => 'count',
    },
);
CLASS->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;

    my $config = $self->config;

    $self->global(1);
    $self->perchar(1);

    return $self;

}

sub augment_global
{

    my $self = shift;

    my $o = $self->modoptions;

    # do we have too many named sets?
    if ( $self->named_count > $o->{max_sets} ) {
        croak "selected ", $self->named_count,
          " sets but we can only support $o->{max_sets}";
    }

    # named sets
    for my $setname ( $self->named_list ) {
        my $namedset = { name => $setname, addons => [] };
        for my $addon ( $self->named_get($setname)->elements ) {
            push @{ $namedset->{addons} }, $addon;
        }
        push @{ $self->globaldata->{named_sets} }, $namedset;
    }

    # class sets
    for my $setname ( $self->class_list ) {
        my $classset = { name => $setname, addons => [] };
        for my $addon ( $self->class_get($setname)->elements ) {
            push @{ $classset->{addons} }, $addon;
        }
        push @{ $self->globaldata->{class_sets} }, $classset;
    }

    return;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my $config = $self->modconfig($char);
    my $log    = WoWUI::Util->logger;

    my %sets = (
        enabled  => Set::Scalar->new,
        disabled => undef,
        prereqs  => Set::Scalar->new,
        alsoadd  => Set::Scalar->new,
    );
    for my $addon ( keys %{ $config->{addons} } ) {
        if ( $f->match( $config->{addons}->{$addon} ) ) {
            $self->enable_addon( $addon, $char, \%sets );
        }
    }
    my $done = 0;
    while ( !$done ) {
        for my $addon ( $sets{alsoadd}->members ) {
            $self->enable_addon( $addon, $char, \%sets );
        }
        for my $addon ( $sets{prereqs}->members ) {
            $self->enable_addon( $addon, $char, \%sets );
        }
        if ( ( $sets{prereqs} + $sets{alsoadd} ) < $sets{enabled} ) {
            $done = 1;
        }
    }

    my $all_addons = Set::Scalar->new( keys %{ $config->{addons} } );
    $sets{disabled} = $all_addons - $sets{enabled};

    my @addons;
    push @addons, map { { name => $_, enabled => 1 } } $sets{enabled}->members;
    push @addons, map { { name => $_, enabled => 0 } } $sets{disabled}->members;
    $self->perchardata->{addons} =
      [ sort { $a->{name} cmp $b->{name} } @addons ];
    $char->addons( $sets{enabled}->clone );

    return;

}

sub enable_addon
{

    my $self  = shift;
    my $addon = shift;
    my $char  = shift;
    my $sets  = shift;

    my $config = $self->modconfig($char);
    my $log    = WoWUI::Util->logger;

    $log->trace("picked up $addon");
    $sets->{enabled}->insert($addon);

    # check for pre-requisites
    if ( exists $config->{addons}->{$addon}->{prereq} ) {
        for my $addon_name ( @{ $config->{addons}->{$addon}->{prereq} } ) {
            unless ( exists $config->{addons}->{$addon_name} ) {
                croak "non-existent prereq '$addon_name' for $addon";
            }
            $sets->{prereqs}->insert($addon_name);
        }
    }
    if ( exists $config->{addons}->{$addon}->{alsoadd} ) {
        for my $addon_name ( @{ $config->{addons}->{$addon}->{alsoadd} } ) {
            unless ( exists $config->{addons}->{$addon_name} ) {
                croak "non-existent also-add '$addon_name' for $addon";
            }
            $sets->{alsoadd}->insert($addon_name);
        }
    }

    # put the addon in the named group
    if ( exists $config->{addons}->{$addon}->{group} ) {
        if ( 'ARRAY' eq ref $config->{addons}->{$addon}->{group} ) {
            for my $group ( @{ $config->{addons}->{$addon}->{group} } ) {
                $self->add_to_named_set( $group, $addon );
            }
        }
        else {
            $self->add_to_named_set( $config->{addons}->{$addon}->{group},
                $addon );
        }
    }

    # put the addon in the named class
    if ( exists $config->{addons}->{$addon}->{class} ) {
        if ( 'ARRAY' eq ref $config->{addons}->{$addon}->{class} ) {
            for my $group ( @{ $config->{addons}->{$addon}->{group} } ) {
                $self->add_to_class_set( $group, $addon );
            }
        }
        else {
            $self->add_to_class_set( $config->{addons}->{$addon}->{class},
                $addon );
        }
    }

    return;

}

sub add_to_named_set
{

    my $self    = shift;
    my $setname = shift;
    my $addon   = shift;

    if ( my $namedset = $self->named_get($setname) ) {
        $namedset->insert($addon);
    }
    else {
        my $namedset = Set::Scalar->new($addon);
        $self->named_set( $setname, $namedset );
    }

    return;

}

sub add_to_class_set
{

    my $self    = shift;
    my $setname = shift;
    my $addon   = shift;

    if ( my $classset = $self->class_get($setname) ) {
        $classset->insert($addon);
    }
    else {
        my $classset = Set::Scalar->new($addon);
        $self->class_set( $setname, $classset );
    }

    return;

}

# keep require happy
1;

#
# EOF
