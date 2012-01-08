package WoWUI::Module::Parrot;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

use WoWUI::ProfileSet;
use WoWUI::Filter::Constants;

# set up class
extends 'WoWUI::Module::Base';
has profileset => (
    is => 'rw',
    isa => 'WoWUI::ProfileSet',
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
    
    $self->global( 1 );
    $self->globalpc( 1 );
    $self->globaldata_clear;
    
    return $self;
    
}

sub augment_global
{

    my $self = shift;

    $self->globaldata_set( p => $self );

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $profile = $self->build_profile( $char, $f );
    
    my $pname = $self->profileset->store( $profile, 'Parrot' );
    $self->globaldata_get( 'chars' )->{$char->dname} = $pname;

}

sub build_profile
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
    
    my $config = $self->modconfig( $char );

    my $profile;
    
    # combat events
    for my $ce_subtype( qw|abbreviateLength throttles notification modifier filters shortenAmount hideUnitNames| ) {
        for my $block( values %{ $config->{combatevents}->{$ce_subtype} } ) {
            if( $f->match( $block->{filter}, F_C0|F_MACH ) ) {
                $profile->{combatevents}->{$ce_subtype} = $block->{$ce_subtype};
                last;
            }
        }
    }
        
    # display, scrollareas, triggers, gametext
    for my $type( qw|display scrollareas triggers gametext| ) {
        for my $block( values %{ $config->{$type} } ) {
            if( $f->match( $block->{filter}, F_C0|F_MACH ) ) {
                $profile->{$type} = $block->{$type};
                last;
            }
        }
    }

    return $profile;

}
