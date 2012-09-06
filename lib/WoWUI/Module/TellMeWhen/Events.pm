#
# $Id: Events.pm 5008 2011-05-29 09:35:09Z james $
#

package WoWUI::Module::TellMeWhen::Events;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

use WoWUI::Module::TellMeWhen::Event;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has Events => (
    is => 'ro',
    isa => 'ArrayRef[WoWUI::Module::TellMeWhen::Event]',
    traits => ['Array','Relevant'],
    relevant => 1,
    default => sub { [] },
    handles => {
        add_event => 'push',
        unshift_event => 'unshift',
        event_count => 'count',
        event_values => 'elements',
        event_clear => 'clear',
    },
);
CLASS->meta->make_immutable;

sub lua
{

    my $self = shift;
    
    if( $self->event_count ) {
        my @events;
        for my $event( $self->event_values ) {
            push @events, '{ ' . $event->lua . ' }';
        }
        return join(', ', @events) . ', ["n"] = ' . $self->event_count;
    }
    
    return '';

}

sub augment_lua { '' }

# keep require happy
1;

#
# EOF
