#
# $Id: Cooldown.pm 5032 2011-06-07 08:01:39Z james $
#

package WoWUI::Module::TellMeWhen::Icon::Condition;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::TellMeWhen::Icon';
with 'WoWUI::Module::TellMeWhen::Icon::Succeed';
has '+priority' => ( default => 6050 );
has '+Type' => ( default => 'conditionicon' );
has '+CustomTex' => ( relevant => 0 );
has '+ShowWhen' => ( relevant => 1 );
has '+Alpha' => ( default => 0.5 );
has [ qw|+CBarOffs +ShowCBar| ] => ( relevant => 1 );
CLASS->meta->make_immutable;

# keep require happy
1;

#
# EOF
