#
# $Id: Dumpable.pm 5002 2011-05-28 01:03:03Z james $
#

package WoWUI::Module::TellMeWhen::Dumpable;
use Moose::Role;

# this isn't really a Moose augment.  It's similar to what I would do if you could augment
# methods mixed in by roles
requires 'augment_lua';

use Carp 'croak';

use WoWUI::Util;
use WoWUI::LuaDumper;

sub lua
{

    my $self = shift;
    
    my $lua;

    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'dump' );

    # iterate over the relevant attributes for this icon type
    my %deferred;
    $log->trace("dumping a ", blessed $self);
    for my $a( $self->meta->get_all_attributes ) {
        next unless( $a->does('WoWUI::Meta::Attribute::Trait::Relevant') && $a->relevant );
        $log->trace("dumping attribute ", $a->name);
        my $snippet = WoWUI::LuaDumper->dump($self, $a);
        if( $snippet ) {
            $lua .= $snippet;
        }
        else {
            # if the dumper couldn't handle it, save it for later
            $deferred{$a->name} = $a;
        }
    }
    if( %deferred ) {
        $log->trace("deferred attributes are ", join(', ', keys %deferred));
    }

    # let classes that consume us handle deferred attributes
    $lua .= $self->augment_lua(\%deferred);

    # die if we didn't handle all deferred attributes
    if( %deferred ) {
        croak "unhandled attributes in " . $self->Name . ": ", join(', ', keys %deferred);
    }

    return $lua;

}

# keep require happy
1;

#
# EOF
