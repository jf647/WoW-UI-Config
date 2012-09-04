#
# $Id: Group.pm 5029 2011-06-06 07:01:30Z james $
#

package WoWUI::Module::TellMeWhen::ConditionSet;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has Conditions => (
    is => 'ro',
    isa => 'ArrayRef[WoWUI::Module::TellMeWhen::Condition]',
    traits => ['Array','Relevant'],
    relevant => 1,
    default => sub { [] },
    handles => {
        add_cond => 'push',
        unshift_cond => 'unshift',
        cond_count => 'count',
        cond_values => 'elements',
        cond_clear => 'clear',
    },
);
CLASS->meta->make_immutable;

sub lua
{

    my $self = shift;
    
    if( $self->cond_count ) {
        my @conds;
        for my $cond( $self->cond_values ) {
            push @conds, '{ ' . $cond->lua . ' }';
        }
        return join(', ', @conds) . ', ["n"] = ' . $self->cond_count;
    }
    
    return '';

}

sub augment_lua { '' }

# keep require happy
1;

#
# EOF
