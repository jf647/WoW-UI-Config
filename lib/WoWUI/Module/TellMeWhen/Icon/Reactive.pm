#
# $Id: Reactive.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Reactive;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
has '+priority' => ( default => 4050 );
has '+Type' => ( default => 'reactive' );
has '+Alpha' => ( default => 0.5 );
has '+CooldownCheck' => ( relevant => 1, default => 1 );
has '+ShowWhen' => ( relevant => 1 );
has [ qw|
    +ManaCheck +RangeCheck +ShowPBar
    +UseActvtnOverlay +IgnoreRunes +PBarOffs
| ] => ( relevant => 1 );
with 'WoWUI::Module::TellMeWhen::Icon::Usable';
with 'WoWUI::Module::TellMeWhen::Icon::SpellName';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Reactive::Off;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Reactive';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Offensive';
CLASS->meta->make_immutable;

package WoWUI::Module::TellMeWhen::Icon::Reactive::Def;
use Moose;

use CLASS;
use namespace::autoclean;

extends 'WoWUI::Module::TellMeWhen::Icon::Reactive';
with 'WoWUI::Module::TellMeWhen::Icon::Priority::Defensive';
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
