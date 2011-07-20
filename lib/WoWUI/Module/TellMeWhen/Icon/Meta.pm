#
# $Id: Meta.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Meta;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
has '+priority' => ( default => 1050 );
has '+Type' => ( default => 'meta' );
has '+Icons' => ( relevant => 1 );
has [ qw|+Alpha +UnAlpha +ConditionAlpha| ] => ( relevant => 0 );
augment select_extra => \&add_meta_members;
augment fixup => \&resolve_meta_position;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

# add the meta icons members to the hidden set
sub add_meta_members
{

    my($self, $set) = @_;

    for my $iname( @{ $self->Icons } ) {
        $set->insert( $iname );
        my $icon = WoWUI::Module::TellMeWhen::Icons->icon_get( $iname );
        unless( $icon ) {
            croak "can't get an icon for '$iname'";
        }
        if( $icon->cond_count ) {
            for my $cond( @{ $icon->Conditions } ) {
                if( 'WoWUI::Module::TellMeWhen::Condition::Icon' eq blessed($cond) ) {
                    $set->insert( $cond->Icon );
                }
            }
        }
    }
    
    # chain delegation
    inner();

}

# resolve the position in the groups of the meta members
sub resolve_meta_position
{

    my($self, $profile) = @_;

    my @newicons;
    for my $icon( @{ $self->Icons } ) {
        my $iconpos = $profile->iconpos_get( $icon );
        push @newicons, 'TellMeWhen_Group' . $iconpos->[0] . '_Icon' . $iconpos->[1];
    }
    $self->Icons( \@newicons );

    # chain delegation
    inner();

}

# keep require happy
1;

#
# EOF
