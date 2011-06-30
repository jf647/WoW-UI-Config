#
# $Id: Char.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Char;
use Moose;

use namespace::autoclean;

# set up class
has 'realm' => ( is => 'rw', isa => 'WoWUI::Realm' );
has level => ( is => 'rw', isa => 'Int' );
has [ qw|dungeontypes professions| ] => ( is => 'rw', isa => 'ArrayRef[Str]' );
has [ qw|name dirname class class_ns race guild watchguild faction| ] => ( is => 'rw', isa => 'Str' );
has [ qw|debug guilded alliance horde played| ] => ( is => 'rw', isa => 'Bool' );
has dualbox_spec => ( is => 'rw', isa => 'Int' );
has spec => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef[Str]',
  default => sub { {} },
  handles => {
    spec_get => 'get',
    spec_set => 'set',
  },
);
has role => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef[ArrayRef[Str]]',
  default => sub { {} },
  handles => {
    role_get => 'get',
    role_set => 'set',
  },
);
has abilities => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef[ArrayRef[Str]]',
  default => sub { {} },
  handles => {
    ability_get => 'get',
    ability_set => 'set',
  },
);
has flags => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef[Set::Scalar]',
  default => sub { {} },
  handles => {
    flags_get => 'get',
    flags_set => 'set',
  },
);
has modoptions => (
  is => 'rw',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    modoption_set => 'set',
    modoption_get => 'get',
    modoptions_list => 'keys',
    modoptions_values => 'values',
  },
);
has addons => ( is => 'rw', isa => 'Set::Scalar' );
around flags_get => \&around_flags_get;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

sub BUILD
{

  my $self = shift;

  # raw profile
  my $rp = WoWUI::Profile->instance->options->{realm}->{$self->realm->name}->{$self->name};

  # directory name override (for those pesky accented people)
  $self->dirname( $rp->{dirname} || $self->name );

  # module options
  if( exists $rp->{modules} ) {
    $self->modoptions( $rp->{modules} );
  }

  # flag sets
  $self->flags_set( 0 => Set::Scalar->new );
  $self->flags_set( 1 => Set::Scalar->new );
  $self->flags_set( 2 => Set::Scalar->new );
  
  # everyone gets this flag
  $self->flags_get(0)->insert('everyone');

  # add machine and profile flags
  $self->flags_get(0)->insert( WoWUI::Profile->instance->flags->members );
  $self->flags_get(0)->insert( WoWUI::Machine->instance->flags->members );

  # common flags
  if( exists $rp->{flags_common} ) {
    $self->flags_get(0)->insert( @{ $rp->{flags_common} } ); 
  }

  # name, realm, class
  $self->class( $rp->{class} );
  my $class_ns = $rp->{class};
  $class_ns =~ s/\s+//g;
  $self->class_ns( $class_ns );
  $self->flags_get(0)->insert('name:'.$self->name);
  $self->flags_get(0)->insert('realm:'.$self->realm->name);
  $self->flags_get(0)->insert('class:'.$rp->{class});

  # levels
  $self->set_level($rp);

  # faction and race
  $self->set_faction($rp);

  # guild
  $self->set_guild($rp);
  
  # specs and roles
  $self->set_spec_role($rp);
  
  # abilities
  $self->set_abilities($rp);
  
  # professions
  $self->set_professions($rp);

  # dungeon types
  $self->set_dungeontypes($rp);
  
}

sub around_flags_get
{

  my $orig = shift;
  my $self = shift;
  my $set = shift;
  
  if( 'all' eq $set ) {
    return $self->$orig(0) + $self->$orig(1) + $self->$orig(2);
  }
  elsif( 'spec1' eq $set ) {
    return $self->$orig(0) + $self->$orig(1);
  }
  elsif( 'spec2' eq $set ) {
    return $self->$orig(0) + $self->$orig(2);
  }
  elsif( 'common' eq $set ) {
    return $self->$orig(0);
  }
  else {
    $self->$orig($set);
  }

}

sub set_professions
{

  my $self = shift;
  my $rp = shift;

  # professions
  if( exists $rp->{professions} ) {
    $self->professions( $rp->{professions} );
    for my $prof( @{ $rp->{professions} } ) {
      if( $prof =~ m/^(\w+):(\d+)$/ ) {
        my $profname = $1;
        my $skill = $2;
        $self->set_prof_brackets($profname, $skill);
      }
      else {
        $self->flags_get(0)->insert("prof:$prof");
      }
    }
  }

}

sub set_prof_brackets
{

  my $self = shift;
  my $prof = shift;
  my $skill = shift;
  
  $self->flags_get(0)->insert("prof:$prof");
  if( 'Tailoring' eq $prof ) {
    if( $skill >= 350 ) {
      $self->flags_get(0)->insert('prof:Tailoring:350+');
    }
  }
  elsif( 'Leatherworking' eq $prof ) {
    if( $skill >= 425 ) {
      $self->flags_get(0)->insert('prof:Leatherworking:425+');
    }
  }
  elsif( 'Blacksmithing' eq $prof ) {
    if( $skill >= 400 ) {
      $self->flags_get(0)->insert('prof:Blacksmithing:400+');
    }
  }
  elsif( 'Inscription' eq $prof ) {
    if( $skill >= 305 ) {
      $self->flags_get(0)->insert('prof:Inscription:305+');
    }
  }
  elsif( 'Enchanting' eq $prof ) {
    if( $skill >= 50 ) {
      $self->flags_get(0)->insert('prof:Enchanting:50+');
    }
  }
  elsif( 'Herbalism' eq $prof ) {
    if( $skill >= 425 ) {
      $self->flags_get(0)->insert('prof:Herbalism:425+');
    }
  }
  elsif( 'Alchemy' eq $prof ) {
    if( $skill >= 500 ) {
      $self->flags_get(0)->insert('prof:Alchemy:500+');
    }
  }
  elsif( 'Cooking' eq $prof ) {
    if( $skill >= 350 ) {
      $self->flags_get(0)->insert('prof:Cooking:350+');
    }
    if( $skill >= 425 ) {
      $self->flags_get(0)->insert('prof:Cooking:425+');
    }
  }
  elsif( 'Jewelcrafting' eq $prof ) {
    if( $skill >= 375 ) {
      $self->flags_get(0)->insert('prof:Jewelcrafting:375+');
    }
    if( $skill >= 450 ) {
     $self->flags_get(0)->insert('prof:Jewelcrafting:450+');
    }
    if( $skill >= 475 ) {
      $self->flags_get(0)->insert('prof:Jewelcrafting:475+');
    }
  }

}

my %consumabletypes = (
    Paladin => {
      Retribution => [ 1, 0 ],
      Holy => [ 0, 1 ],
      Protection => [ 1, 0 ],
    },
    Shaman => {
      Enhancement => [ 1, 0 ],
      Elemental => [ 1, 1 ],
      Restoration => [ 0, 1 ],
    },
    Warrior => [ 1, 0 ],
    Druid => {
      Balance => [ 0, 1 ],
      Restoration => [ 0, 1 ],
      'Feral Combat' => [ 1, 0 ],
    },
    'Death Knight' => [ 1, 0 ],
    Priest => [ 0, 1 ],
    Rogue => [ 1, 0 ],
    Hunter => [ 1, 0 ],
    Mage => [ 0, 1 ],
    Warlock => [ 1, 1 ],
);
sub set_consumable_type
{

  my $self = shift;
  my $specnum = shift;
  my $spec = shift;

  if( 'ARRAY' eq ref $consumabletypes{$self->class} ) {
    if( $consumabletypes{$self->class}->[0] ) {
      $self->flags_get(0)->insert('classusesfood');
      $self->flags_get($specnum)->insert('specusesfood');
    }
    if( $consumabletypes{$self->class}->[1] ) {
      $self->flags_get(0)->insert('classusesmana');
      $self->flags_get($specnum)->insert('specusesmana');
    }
  }
  else {
    if( $consumabletypes{$self->class}->{$spec}->[0] ) {
      $self->flags_get(0)->insert('classusesfood');
      $self->flags_get($specnum)->insert('specusesfood');
    }
    if( $consumabletypes{$self->class}->{$spec}->[1] ) {
      $self->flags_get(0)->insert('classusesmana');
      $self->flags_get($specnum)->insert('specusesmana');
    }
  }

}

my %faction = (
  'Night Elf' => 'Alliance',
  Draenei => 'Alliance',
  Worgen => 'Alliance',
  Dwarf => 'Alliance',
  Gnome => 'Alliance',
  Human => 'Alliance',
  Troll => 'Horde',
  Tauren => 'Horde',
  Orc => 'Horde',
  'Blood Elf' => 'Horde',
  Goblin => 'Horde',
  Undead => 'Horde',
);
sub set_faction
{

  my $self = shift;
  my $rp = shift;
  
  if( my $faction = $faction{$rp->{race}} ) {
    $self->race($rp->{race});
    $self->flags_get(0)->insert("race:$rp->{race}");
    $self->faction( lc $faction );
    $self->flags_get(0)->insert("faction:".$self->faction);
    $self->alliance( 'Alliance' eq $faction );
    $self->horde( 'Horde' eq $faction );
  }
  else {
    croak "unknown faction for race '$rp->{race}'";
  }

}

my %roles = (
  Paladin => {
    Retribution => [ 'Strength DPS', 'Melee DPS' ],
    Holy => [ 'Healer' ],
    Protection => [ 'Tank'] ,
  },
  Shaman => {
    Enhancement => [ 'Agility DPS', 'Ranged DPS' ],
    Elemental => [ 'Intellect DPS', 'Caster DPS' ],
    Restoration => [ 'Healer' ],
  },
  Warrior => {
    Protection => [ 'Tank' ],
    Fury => [ 'Strength DPS', 'Melee DPS' ],
    Arms => [ 'Strength DPS', 'Melee DPS' ],
  },
  Druid => {
    Balance => [ 'Intellect DPS', 'Caster DPS' ],
    Restoration => [ 'Healer' ],
  },
  'Death Knight' => {
    Blood => [ 'Tank' ],
    Frost => [ 'Strength DPS', 'Melee DPS' ],
    Unholy => [ 'Strength DPS', 'Melee DPS', 'Petclass' ],
  },
  Priest => {
    Holy => [ 'Healer' ],
    Discipline => [ 'Healer' ],
    Shadow => [ 'Intellect DPS', 'Caster DPS' ],
  },
  Rogue => [ 'Agility DPS', 'Melee DPS' ],
  Hunter => [ 'Agility DPS', 'Ranged DPS', 'Petclass' ],
  Mage => {
    Arcane => [ 'Intellect DPS', 'Caster DPS' ],
    Fire => [ 'Intellect DPS', 'Caster DPS' ],
    Frost => [ 'Intellect DPS', 'Caster DPS', 'Petclass' ],
  },
  Warlock => [ 'Intellect DPS', 'Caster DPS', 'Petclass' ],
);
sub set_spec_role
{

  my $self = shift;
  my $rp = shift;

  for my $specnum( 1, 2 ) {
    if( my $spec = $rp->{"spec${specnum}"} ) {
      $self->set_consumable_type($specnum, $spec);
      $self->spec_set($specnum, $rp->{"spec${specnum}"} );
      $self->flags_get($specnum)->insert("spec:$spec");
      if( exists $rp->{"spec${specnum}_subspec"} ) {
        for my $subspec( @{ $rp->{"spec${specnum}_subspec"} } ) {
          $self->flags_get($specnum)->insert("subspec:$subspec");
        }
      }
      if( exists $rp->{"flags_spec${specnum}"} ) {
        $self->flags_get($specnum)->insert( @{ $rp->{"flags_spec${specnum}"} } ); 
      }
      if( exists $rp->{"role_spec${specnum}"} ) {
         $self->role_set( $specnum, $rp->{"role_spec${specnum}"} );
         for my $role( @{ $rp->{"role_spec${specnum}"} } ) {
           $self->flags_get($specnum)->insert( "role:$role" );
         }
      }
      else {
        if( 'HASH' eq ref $roles{$self->class} ) {
          if( exists $roles{$self->class}->{$spec} ) {
            $self->role_set( $specnum, $roles{$self->class}->{$spec} );
            for my $role( @{ $roles{$self->class}->{$spec} } ) {
              $self->flags_get($specnum)->insert( "role:$role" );
            }
          }
          else {
            croak "can't determine role for ", $self->class, "/$spec";
          }
        }
        else {
          $self->role_set( $specnum, $roles{$self->class} );
          for my $role( @{ $roles{$self->class} } ) {
            $self->flags_get($specnum)->insert( "role:$role" );
          }
        }
      }
    }
  }
  
  if( exists $rp->{dualbox_spec} ) {
      $self->dualbox_spec( $rp->{dualbox_spec} );
  }

}

sub set_guild
{

  my $self = shift;
  my $rp = shift;

  if( exists $rp->{guild} ) {
    $self->guilded(1);
    $self->guild($rp->{guild});
    $self->flags_get(0)->insert('guilded');
    $self->flags_get(0)->insert("guild:$rp->{guild}");
  }
  else {
    $self->guilded(0);
    $self->flags_get(0)->insert('unguilded');
    if( exists $rp->{watchguild} ) {
      $self->flags_get(0)->insert('watchguild');
      $self->flags_get(0)->insert("watchguild:$rp->{watchguild}");
      $self->watchguild($rp->{watchguild});
    }
  }

}

sub set_dungeontypes
{

  my $self = shift;
  my $rp = shift;

  if( exists $rp->{dungeontypes} ) {
    $self->dungeontypes( $rp->{dungeontypes} );
    for my $dt( @{ $rp->{dungeontypes} } ) {
      $self->flags_get(0)->insert("dungeontype:$dt");
    }
  }

}

my %abilities = (
  Paladin => {
    Retribution => [ 'cleanse', 'cleanse:poison', 'cleanse:disease', 'interrupt', 'cc', 
      'cc:demon', 'cc:dragon', 'cc:giant', 'cc:human', 'cc:undead', 'stun', 'resurrect' ],
    Holy => [ 'cleanse', 'cleanse:poison', 'cleanse:disease', 'cleanse:magic', 'stun', 'resurrect' ],
    Protection => [ 'cleanse', 'cleanse:poison', 'cleanse:disease', 'stun', 'resurrect' ],
  },
  Shaman => {
    Enhancement => [ 'cleanse', 'cleanse:curse', 'interrupt', 'cc', 'cc:human', 'cc:beast', 'cc:elemental', 'resurrect' ],
    Elemental => [ 'cleanse', 'cleanse:curse', 'interrupt', 'cc', 'cc:human', 'cc:beast', 'cc:elemental', 'resurrect' ],
    Restoration => [ 'cleanse', 'cleanse:curse', 'cleanse:magic', 'interrupt', 'cc', 'cc:human', 'cc:beast', 'cc:elemental', 'resurrect' ],
  },
  Druid => {
    Balance => [ 'cleanse', 'cleanse:poison', 'cleanse:curse', 'resurrect', 'battlerez' ],
    Restoration => [ 'cleanse', 'cleanse:poison', 'cleanse:curse', 'cleanse:magic', 'resurrect', 'battlerez' ],
    'Feral Combat' => [ 'cleanse', 'cleanse:poison', 'cleanse:curse', 'interrupt', 'resurrect', 'battlerez' ],
  },
  Priest => {
    Holy => [ 'cleanse', 'cleanse:disease', 'cleanse:magic', 'cc', 'cc:undead', 'resurrect' ],
    Discipline => [ 'cleanse', 'cleanse:disease', 'cleanse:magic', 'cc', 'cc:undead', 'resurrect' ],
    Shadow => [ 'cleanse', 'cleanse:disease', 'cleanse:magic', 'cc', 'cc:undead', 'resurrect' ],
  },
  Hunter => {
    Survival => [ 'cc', 'cc:undead', 'cc:human', 'cc:demon', 'cc:beast', 'cc:elemental',
      'cc:demon', 'cc:giant', 'cc:dragon' ],
    Marksmanship => [ 'cc', 'cc:undead', 'cc:human', 'cc:demon', 'cc:beast', 'cc:elemental',
      'cc:demon', 'cc:giant', 'cc:dragon', 'interrupt' ],
    'Beast Mastery' => [ 'cc', 'cc:undead', 'cc:human', 'cc:demon', 'cc:beast', 'cc:elemental',
      'cc:demon', 'cc:giant', 'cc:dragon' ],
  },
  Rogue => [ 'interrupt' ],
  'Death Knight' => [ 'interrupt', 'battlerez' ],
  Warrior => [ 'interrupt' ],
  Mage => [ 'interrupt', 'cc', 'cc:human', 'cc:beast' ],
  Warlock => [ 'resurrect', 'cc' ],
);
sub set_abilities
{

  my $self = shift;
  my $rp = shift;

  for my $specnum( 1, 2 ) {
    if( my $spec = $rp->{"spec${specnum}"} ) {
      if( 'HASH' eq ref $abilities{$self->class} ) {
        if( exists $abilities{$self->class}->{$spec} ) {
          $self->ability_set($specnum, $abilities{$self->class}->{$spec});
          for my $ability( @{ $abilities{$self->class}->{$spec} } ) {
            $self->flags_get($specnum)->insert("ability:$ability");
          }
        }
      }
      elsif( 'ARRAY' eq ref $abilities{$self->class} ) {
        $self->ability_set($specnum, $abilities{$self->class});
        for my $ability( @{ $abilities{$self->class} } ) {
          $self->flags_get($specnum)->insert("ability:$ability");
        }
      }
    }
  }
  
}

sub set_level
{

    my $self = shift;
    my $rp = shift;

    my $config = WoWUI::Config->instance->cfg;

    $self->level( $rp->{level} );

    if( $rp->{level} != $config->{levelcap} ) {
        $self->flags_get(0)->insert('leveling');
    }
    else {
        $self->flags_get(0)->insert('levelcap');
    }

}

# keep require happy
1;

#
# EOF
