#
# $Id: Reactive.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Reactive;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
has '+priority' => ( default => 4050 );
has '+Type' => ( default => 'reactive' );
has '+ShowWhen' => ( relevant => 1 );
has '+Alpha' => ( default => 0.5 );
has '+CooldownCheck' => ( relevant => 1, default => 1 );
has [ qw|
    +ManaCheck +RangeCheck +ShowPBar
    +UseActvtnOverlay +IgnoreRunes +PBarOffs
| ] => ( relevant => 1 );
__PACKAGE__->meta->make_immutable;

# constructor
sub BUILD
{

    my $self = shift;
    my $icfg = shift;

    # usable / unusable
    if( exists $icfg->{unusable} ) {
        $self->ShowWhen( 'unalpha' );
        $self->UnAlpha( 0.5 );
    }
    elsif( exists $icfg->{always} ) {
        $self->ShowWhen( 'always' );
        $self->UnAlpha( 0.5 );
    }
    
    return $self;

}

package WoWUI::Module::TellMeWhen::Icon::Reactive::Off;
use Moose;

use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Reactive';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Offensive';
__PACKAGE__->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Reactive::Def;
use Moose;

use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Reactive';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Defensive';
__PACKAGE__->meta->make_immutable;

# keep require happy
1;

#
# EOF
