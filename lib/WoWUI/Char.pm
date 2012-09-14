
# $Id: Char.pm 5031 2011-06-06 22:07:31Z james $
#

package WoWUI::Char;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;
use feature 'switch';

# set up class
with 'WoWUI::ModOptions';
with 'WoWUI::ModConfig';
has realm => ( is => 'rw', isa => 'WoWUI::Realm', required => 1 );
has level => ( is => 'rw', isa => 'Int' );
has cfg   => ( is => 'rw', isa => 'HashRef' );
has [qw|dungeontypes professions|] => ( is => 'rw', isa => 'ArrayRef[Str]' );
has [qw|name dirname class class_ns race guild watchguild faction|] =>
  ( is => 'rw', isa => 'Str' );
has [qw|debug guilded alliance horde played|] => ( is => 'rw', isa => 'Bool' );
has dualbox_spec => ( is => 'rw', isa => 'Int' );
has spec => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub { {} },
    handles => {
        spec_get => 'get',
        spec_set => 'set',
    },
);
has talents => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[Str]]',
    default => sub { {} },
    handles => {
        talents_get => 'get',
        talents_set => 'set',
    },
);
has glyphs => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[Str]]',
    default => sub { {} },
    handles => {
        glyphs_get => 'get',
        glyphs_set => 'set',
    },
);
has role => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[Str]]',
    default => sub { {} },
    handles => {
        role_get => 'get',
        role_set => 'set',
    },
);
has abilities => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[Str]]',
    default => sub { {} },
    handles => {
        ability_get => 'get',
        ability_set => 'set',
    },
);
has flags => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[Set::Scalar]',
    default => sub { {} },
    handles => {
        flags_get => 'get',
        flags_set => 'set',
    },
);
has addons => ( is => 'rw', isa => 'Set::Scalar' );
around flags_get => \&around_flags_get;
CLASS->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

sub BUILD {

    my $self = shift;

    # directory name override (for those pesky accented people)
    $self->dirname( $self->cfg->{dirname} || $self->name );

    # module options
    $self->set_modconfig( $self->cfg );
    $self->set_modoptions( $self->cfg );

    # flag sets
    $self->flags_set( 0 => Set::Scalar->new );
    $self->flags_set( 1 => Set::Scalar->new );
    $self->flags_set( 2 => Set::Scalar->new );

    # common flags
    if ( exists $self->cfg->{flags} ) {
        $self->flags_get(0)->insert( @{ $self->cfg->{flags} } );
    }

    # name, realm, class
    $self->class( $self->cfg->{class} );
    my $class_ns = $self->cfg->{class};
    $class_ns =~ s/\s+//gx;
    $self->class_ns($class_ns);
    $self->flags_get(0)->insert( 'name:' . $self->name );
    $self->flags_get(0)->insert( 'realm:' . $self->realm->name );
    $self->flags_get(0)->insert( 'class:' . $self->cfg->{class} );

    # levels
    $self->set_level;

    # faction and race
    $self->set_faction;

    # guild
    $self->set_guild;

    # specs, roles and talents
    $self->set_spec_role_talents_glyphs;

    # abilities
    $self->set_abilities;

    # professions
    $self->set_professions;

    # dungeon types
    $self->set_dungeontypes;

    return $self;

}

sub around_flags_get {

    my $orig    = shift;
    my $self    = shift;
    my $flagset = shift;

    given ($flagset) {
        when ('all') {
            return $self->$orig(0) + $self->$orig(1) + $self->$orig(2);
        }
        when ('spec1') {
            return $self->$orig(0) + $self->$orig(1);
        }
        when ('spec2') {
            return $self->$orig(0) + $self->$orig(2);
        }
        when ('common') {
            return $self->$orig(0);
        }
        default {
            return $self->$orig($flagset);
        }
    }

}

sub set_professions {

    my $self = shift;

    # professions
    if ( exists $self->cfg->{professions} ) {
        $self->professions( $self->cfg->{professions} );
        for my $prof ( @{ $self->cfg->{professions} } ) {
            if ( $prof =~ m/^(\w+):(\d+)$/x ) {
                my $profname = $1;
                my $skill    = $2;
                $self->set_prof_brackets( $profname, $skill );
            }
            else {
                $self->flags_get(0)->insert("prof:$prof");
            }
        }
    }

    return;

}

sub set_prof_brackets {

    my $self  = shift;
    my $prof  = shift;
    my $skill = shift;

    my @toadd;
    given ($skill) {
        when ( >= 50 ) {
            push @toadd, '50+';
        }
        when ( >= 75 ) {
            push @toadd, 'Apprentice';
        }
        when ( >= 150 ) {
            push @toadd, 'Journeyman';
        }
        when ( >= 225 ) {
            push @toadd, 'Expert';
        }
        when ( >= 300 ) {
            push @toadd, 'Artisan';
        }
        when ( >= 305 ) {
            push @toadd, '305+';
        }
        when ( >= 350 ) {
            push @toadd, '350+';
        }
        when ( >= 375 ) {
            push @toadd, 'Master';
        }
        when ( >= 400 ) {
            push @toadd, '400+';
        }
        when ( >= 425 ) {
            push @toadd, '425+';
        }
        when ( >= 450 ) {
            push @toadd, 'Grand Master';
        }
        when ( >= 475 ) {
            push @toadd, '475+';
        }
        when ( >= 500 ) {
            push @toadd, '500+';
        }
        when ( >= 525 ) {
            push @toadd, 'Illustrious Grand Master';
        }
        when ( >= 600 ) {
            push @toadd, 'Zen Master';
        }
    }
    $self->flags_get(0)->insert( map { "prof:$prof:$_" } @toadd );

    return;

}

my %consumabletypes = (
    Paladin => {
        Retribution => [ 1, 0 ],
        Holy        => [ 0, 1 ],
        Protection  => [ 1, 0 ],
    },
    Shaman => {
        Enhancement => [ 1, 0 ],
        Elemental   => [ 1, 1 ],
        Restoration => [ 0, 1 ],
    },
    Warrior => [ 1, 0 ],
    Druid   => {
        Balance     => [ 0, 1 ],
        Restoration => [ 0, 1 ],
        Feral       => [ 1, 0 ],
        Guardian    => [ 1, 0 ],
    },
    'Death Knight' => [ 1, 0 ],
    Priest         => [ 0, 1 ],
    Rogue          => [ 1, 0 ],
    Hunter         => [ 1, 0 ],
    Mage           => [ 0, 1 ],
    Warlock        => [ 1, 1 ],
    Monk           => [ 1, 1 ],
);

sub set_consumable_type {

    my $self    = shift;
    my $specnum = shift;
    my $spec    = shift;

    if ( 'ARRAY' eq ref $consumabletypes{ $self->class } ) {
        if ( $consumabletypes{ $self->class }->[0] ) {
            $self->flags_get(0)->insert('classusesfood');
            $self->flags_get($specnum)->insert('specusesfood');
        }
        if ( $consumabletypes{ $self->class }->[1] ) {
            $self->flags_get(0)->insert('classusesmana');
            $self->flags_get($specnum)->insert('specusesmana');
        }
    }
    else {
        if ( $consumabletypes{ $self->class }->{$spec}->[0] ) {
            $self->flags_get(0)->insert('classusesfood');
            $self->flags_get($specnum)->insert('specusesfood');
        }
        if ( $consumabletypes{ $self->class }->{$spec}->[1] ) {
            $self->flags_get(0)->insert('classusesmana');
            $self->flags_get($specnum)->insert('specusesmana');
        }
    }

    return;

}

my %faction = (
    'Night Elf' => 'Alliance',
    Draenei     => 'Alliance',
    Worgen      => 'Alliance',
    Dwarf       => 'Alliance',
    Gnome       => 'Alliance',
    Human       => 'Alliance',
    Troll       => 'Horde',
    Tauren      => 'Horde',
    Orc         => 'Horde',
    'Blood Elf' => 'Horde',
    Goblin      => 'Horde',
    Undead      => 'Horde',
);

sub set_faction {

    my $self = shift;

    if ( my $faction = $faction{ $self->cfg->{race} } ) {
        $self->race( $self->cfg->{race} );
        $self->flags_get(0)->insert( 'race:' . $self->cfg->{race} );
        $self->faction( lc $faction );
        $self->flags_get(0)->insert( "faction:" . $self->faction );
        $self->alliance( 'Alliance' eq $faction );
        $self->horde( 'Horde'       eq $faction );
    }
    else {
        croak "unknown faction for race '", $self->cfg->{race}, "'";
    }

    return;

}

my %roles = (
    Paladin => {
        Retribution => [ 'Strength DPS', 'Melee DPS' ],
        Holy        => ['Healer'],
        Protection  => ['Tank'],
    },
    Shaman => {
        Enhancement => [ 'Agility DPS',   'Ranged DPS' ],
        Elemental   => [ 'Intellect DPS', 'Caster DPS' ],
        Restoration => ['Healer'],
    },
    Warrior => {
        Protection => ['Tank'],
        Fury       => [ 'Strength DPS', 'Melee DPS' ],
        Arms       => [ 'Strength DPS', 'Melee DPS' ],
    },
    Druid => {
        Balance     => [ 'Intellect DPS', 'Caster DPS' ],
        Restoration => ['Healer'],
        Feral       => [ 'Melee DPS',     'Agility DPS' ],
        Guardian    => ['Tank'],
    },
    'Death Knight' => {
        Blood  => ['Tank'],
        Frost  => [ 'Strength DPS', 'Melee DPS' ],
        Unholy => [ 'Strength DPS', 'Melee DPS', 'Petclass' ],
    },
    Priest => {
        Holy       => ['Healer'],
        Discipline => ['Healer'],
        Shadow     => [ 'Intellect DPS', 'Caster DPS' ],
    },
    Rogue  => [ 'Agility DPS', 'Melee DPS' ],
    Hunter => [ 'Agility DPS', 'Ranged DPS', 'Petclass' ],
    Mage => {
        Arcane => [ 'Intellect DPS', 'Caster DPS' ],
        Fire   => [ 'Intellect DPS', 'Caster DPS' ],
        Frost  => [ 'Intellect DPS', 'Caster DPS', 'Petclass' ],
    },
    Warlock => [ 'Intellect DPS', 'Caster DPS', 'Petclass' ],
    Monk    => {
        Windwalker => [ 'Agility DPS', 'Melee DPS' ],
        Mistweaver => ['Healer'],
        Brewmaster => ['Tank'],
    },
);

sub set_spec_role_talents_glyphs {

    my $self = shift;

    for my $specnum ( 1, 2 ) {
        if ( exists $self->cfg->{spec}->{$specnum} ) {

            # spec tree
            my $tree = $self->cfg->{spec}->{$specnum}->{tree};
            $self->spec_set( $specnum, $tree );

            # consumable type
            $self->set_consumable_type( $specnum, $tree );
            $self->flags_get($specnum)->insert("spec:$tree");

            # spec flags
            if ( exists $self->cfg->{spec}->{$specnum}->{flags} ) {
                $self->flags_get($specnum)
                  ->insert( @{ $self->cfg->{spec}->{$specnum}->{flags} } );
            }

            # spec roles
            if ( 'HASH' eq ref $roles{ $self->class } ) {
                if ( exists $roles{ $self->class }->{$tree} ) {
                    $self->role_set( $specnum,
                        $roles{ $self->class }->{$tree} );
                    for my $role ( @{ $roles{ $self->class }->{$tree} } ) {
                        $self->flags_get($specnum)->insert("role:$role");
                    }
                }
                else {
                    croak "can't determine role for ", $self->class, "/$tree";
                }
            }
            else {
                $self->role_set( $specnum, $roles{ $self->class } );
                for my $role ( @{ $roles{ $self->class } } ) {
                    $self->flags_get($specnum)->insert("role:$role");
                }
            }

            # spec talents
            if ( exists $self->cfg->{spec}->{$specnum}->{talents} ) {
                $self->talents_set( $specnum,
                    $self->cfg->{spec}->{$specnum}->{talents} );
                for
                  my $talent ( @{ $self->cfg->{spec}->{$specnum}->{talents} } )
                {
                    $self->flags_get($specnum)->insert("talent:$talent");
                }
            }

            # spec glyphs
            if ( exists $self->cfg->{spec}->{$specnum}->{glyphs} ) {
                $self->glyphs_set( $specnum,
                    $self->cfg->{spec}->{$specnum}->{glyphs} );
                for my $glyph ( @{ $self->cfg->{spec}->{$specnum}->{glyphs} } )
                {
                    $self->flags_get($specnum)->insert("glyph:$glyph");
                }
            }
        }
    }

    if ( exists $self->cfg->{dualbox_spec} ) {
        $self->dualbox_spec( $self->cfg->{dualbox_spec} );
    }

    return;

}

sub set_guild {

    my $self = shift;

    if ( exists $self->cfg->{guild} ) {
        $self->guilded(1);
        $self->guild( $self->cfg->{guild} );
        $self->flags_get(0)->insert('guilded');
        $self->flags_get(0)->insert( 'guild:' . $self->cfg->{guild} );
    }
    else {
        $self->guilded(0);
        $self->flags_get(0)->insert('unguilded');
        if ( exists $self->cfg->{watchguild} ) {
            $self->flags_get(0)->insert('watchguild');
            $self->flags_get(0)
              ->insert( 'watchguild:' . $self->cfg->{watchguild} );
            $self->watchguild( $self->cfg->{watchguild} );
        }
    }

    return;

}

sub set_dungeontypes {

    my $self = shift;

    if ( exists $self->cfg->{dungeontypes} ) {
        $self->dungeontypes( $self->cfg->{dungeontypes} );
        for my $dt ( @{ $self->cfg->{dungeontypes} } ) {
            $self->flags_get(0)->insert("dungeontype:$dt");
        }
    }

    return;

}

my %abilities = (
    Paladin => {
        Retribution => [ 'cleanse', 'interrupt', 'cc', 'stun', 'resurrect' ],
        Holy       => [ 'cleanse', 'stun', 'resurrect' ],
        Protection => [ 'cleanse', 'stun', 'resurrect' ],
    },
    Shaman => {
        Enhancement => [ 'cleanse', 'interrupt', 'cc', 'resurrect' ],
        Elemental   => [ 'cleanse', 'interrupt', 'cc', 'resurrect' ],
        Restoration => [ 'cleanse', 'interrupt', 'cc', 'resurrect' ],
    },
    Druid => {
        Balance     => [ 'cleanse', 'resurrect', 'battlerez' ],
        Restoration => [ 'cleanse', 'resurrect', 'battlerez' ],
        Feral       => [ 'cleanse', 'interrupt', 'resurrect', 'battlerez' ],
        Guardian    => [ 'cleanse', 'interrupt', 'resurrect', 'battlerez' ],
    },
    Priest => {
        Holy       => [ 'cleanse', 'cc', 'resurrect' ],
        Discipline => [ 'cleanse', 'cc', 'resurrect' ],
        Shadow     => [ 'cleanse', 'cc', 'resurrect', 'interrupt' ],
    },
    Hunter => {
        Survival        => ['cc'],
        Marksmanship    => [ 'cc', 'interrupt' ],
        'Beast Mastery' => ['cc'],
    },
    Rogue          => ['interrupt'],
    'Death Knight' => [ 'interrupt', 'battlerez' ],
    Warrior        => ['interrupt'],
    Mage           => [ 'interrupt', 'cc', 'cleanse' ],
    Warlock        => {
        Affliction  => [ 'resurrect', 'cc', 'battlerez', 'interrupt' ],
        Demonology  => [ 'resurrect', 'cc', 'battlerez' ],
        Destruction => [ 'resurrect', 'cc', 'battlerez' ],
    },
    Monk => [ 'resurrect', 'cc', 'cleanse', 'interrupt' ],
);

sub set_abilities {

    my $self = shift;

    for my $specnum ( 1, 2 ) {
        if ( exists $self->cfg->{spec}->{$specnum} ) {
            my $tree = $self->cfg->{spec}->{$specnum}->{tree};
            if ( 'HASH' eq ref $abilities{ $self->class } ) {
                if ( exists $abilities{ $self->class }->{$tree} ) {
                    $self->ability_set( $specnum,
                        $abilities{ $self->class }->{$tree} );
                    for my $ability ( @{ $abilities{ $self->class }->{$tree} } )
                    {
                        $self->flags_get($specnum)->insert("ability:$ability");
                    }
                }
            }
            elsif ( 'ARRAY' eq ref $abilities{ $self->class } ) {
                $self->ability_set( $specnum, $abilities{ $self->class } );
                for my $ability ( @{ $abilities{ $self->class } } ) {
                    $self->flags_get($specnum)->insert("ability:$ability");
                }
            }
        }
    }

    return;

}

sub set_level {

    my $self = shift;

    my $config = WoWUI::Config->instance->cfg;

    $self->level( $self->cfg->{level} );

    if ( $self->cfg->{level} != $config->{levelcap} ) {
        $self->flags_get(0)->insert('leveling');
    }
    else {
        $self->flags_get(0)->insert('levelcap');
    }

    return;

}

sub rname {

    my $self = shift;

    return $self->name . ' of ' . $self->realm->name;

}

sub dname {

    my $self = shift;

    return $self->name . ' - ' . $self->realm->name;

}

# keep require happy
1;

#
# EOF
