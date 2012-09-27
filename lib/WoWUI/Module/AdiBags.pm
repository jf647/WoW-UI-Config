package WoWUI::Module::AdiBags;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

use WoWUI::ProfileSet;
use WoWUI::Filter::Constants;

# set up class
extends 'WoWUI::Module::Base';
has profileset => (
    is      => 'rw',
    isa     => 'WoWUI::ProfileSet',
    default => sub { WoWUI::ProfileSet->new },
);
after 'globaldata_clear' => sub {
    my $self = shift;
    $self->globaldata_set( chars => {} );
};
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILD
{

    my $self = shift;

    $self->global(1);
    $self->globalpc(1);
    $self->globaldata_clear;

    return $self;

}

sub augment_global
{

    my $self = shift;

    $self->globaldata_set( adi => $self );

    return;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my $profile = $self->build_profile( $char, $f );

    my $pname = $self->profileset->store( $profile, 'AdiBags' );
    $self->globaldata_get('chars')->{ $char->dname } = $pname;

    return;

}

sub build_profile
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my $config = $self->modconfig($char);

    my $profile;

    # generic
    for my $type (qw|frame override|) {
        for my $block ( values %{ $config->{$type} } ) {
            $profile->{"has_$type"} = 0;
            if ( $f->match( $block->{filter}, F_CALL | F_MACH ) ) {
                $profile->{$type} = $block->{$type};
                $profile->{"has_$type"} = 1;
                last;
            }
        }
    }

    # rules
    for my $blockname ( keys %{ $config->{rules} } ) {
        my $block = $config->{rules}->{$blockname};
        $block->{rule}->{name} = $blockname;
        if ( $f->match( $block->{filter}, F_CALL | F_MACH ) ) {
            push @{ $profile->{rules} }, $block->{rule};
        }
    }

    return $profile;

}

1;
