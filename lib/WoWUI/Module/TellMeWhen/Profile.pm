#
# $Id: Profile.pm 5032 2011-06-07 08:01:39Z james $
#

package WoWUI::Module::TellMeWhen::Profile;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
use WoWUI::Meta::Attribute::Trait::Relevant;
with 'WoWUI::Module::TellMeWhen::Dumpable';
has config => ( is => 'ro', isa => 'HashRef' );
has char => ( is => 'rw', isa => 'WoWUI::Char', required => 1 );
has modoptions => ( is => 'rw', isa => 'HashRef', required => 1 );
has nextgrouppos => ( is => 'rw', isa => 'WoWUI::Module::TellMeWhen::Point' );
has filtergroups => ( is => 'rw', isa => 'WoWUI::FilterGroups', required => 1 );
has widestgroup => ( is => 'rw', isa => 'Num', default => 0 );
has groupscale => ( is => 'rw', isa => 'Num', default => 2 );
has tmw => ( is => 'rw', isa => 'WoWUI::Module::TellMeWhen', weak_ref => 1, required => 1 );
has Version => ( is => 'ro', isa => 'Int', traits => ['Relevant'], relevant => 1, lazy_build => 1 );
has Locked => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has NumGroups => ( is => 'ro', isa => 'Num', traits => ['Relevant'], relevant => 1 );
around 'NumGroups' => sub { $_[1]->group_count };
has Interval => ( is => 'rw', isa => 'Num', default => 0.06, traits => ['Relevant'], relevant => 1 );
has EffThreshold => ( is => 'rw', isa => 'Num', default => 15, traits => ['Relevant'], relevant => 1 );
has TextureName => ( is => 'rw', isa => 'Str', default => 'Blizzard', traits => ['Relevant'], relevant => 1 );
has DrawEdge => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has SoundChannel => ( is => 'rw', isa => 'Str', default => 'SFX', traits => ['Relevant'], relevant => 1 );
has ReceiveComm => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has WarnInvalids => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has BarGCD => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has ClockGCD => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has CheckOrder => ( is => 'rw', isa => 'Int', default => -1, traits => ['Relevant'], relevant => 1 );
has SUG_atBeginning => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has ColorNames => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has AlwaysSubLinks => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has ColorMSQ => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has OnlyMSQ => ( is => 'rw', isa => 'Bool', default => 0, traits => ['Relevant'], relevant => 1 );
has Colors => (
    is => 'rw',
    isa => 'HashRef[HashRef[Num]]',
    default => sub { {
        CBC  => { r => 0, g => 1, b => 0, Override => 0, a => 1 },
        CBS  => { r => 1, g => 0, b => 0, Override  => 0, a => 1 },
        OOR  => { r => 0.5, g => 0.5, b => 0.5, Override => 0 },
        OOM  => { r => 0.5, g => 0.5, b => 0.5, Override => 0 },
        OORM => { r => 0.5, g => 0.5, b => 0.5, Override => 0 },
        CTA  => { r => 1, g => 1, b => 1, Override => 0 },
        COA  => { r => 0.5, g => 0.5, b => 0.5, Override => 0 },
        CTS  => { r => 1, g => 1, b => 1, Override => 0 },
        COS  => { r => 1, g => 1, b => 1, Override => 0 },
        NA   => { r => 1, g => 1, b => 1, Override => 0 },
        NS   => { r => 1, g => 1, b => 1, Override => 0 },
    } },
    traits => ['Relevant'],
    relevant => 1,
);
has Groups => (
    is => 'ro',
    isa => 'ArrayRef[WoWUI::Module::TellMeWhen::Group]',
    traits => ['Array','Relevant'],
    relevant => 1,
    default => sub { [] },
    handles => {
        add_group => 'push',
        get_group => 'get',
        group_count => 'count',
    },
);
has groupspec_to_point => (
    is => 'bare',
    isa => 'HashRef[WoWUI::Module::TellMeWhen::Point]',
    traits => ['Hash'],
    handles => {
        groupspec_set => 'set',
        groupspec_get => 'get',
    },
);
has icon_to_position => (
    is => 'bare',
    isa => 'HashRef[ArrayRef[Int]]',
    traits => ['Hash'],
    handles => {
        iconpos_set => 'set',
        iconpos_get => 'get',
        iconpos_exists => 'exists',
    },
);
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;
    my $a = shift;
    my $config = $a->{config};

    # set the update interval
    $self->Interval( $self->modoptions->{interval} );

    # create a point for the first group
    $self->nextgrouppos( WoWUI::Module::TellMeWhen::Point->new( %{ $self->modoptions->{anchor} } ) );

    return $self;

}

sub _build_Version
{

    my $self = shift;
    
    return $self->tmw->tmwversion;

}

# populate a profile with groups
sub populate
{

    my $self = shift;
    my %a = @_;
    
    my $f = $a{f};
    my $config = $a{config};
    
    my $desc = $self->char->rname;
    
    my $log = WoWUI::Util->logger;

    # select icons
    my %i;
    for my $spec( 1, 2 ) {
        for my $combat( qw|in out| ) {
            $log->debug("selecting icons for spec $spec combat $combat");
            ($i{selected}->{$spec}->{$combat}, $i{hidden}->{$spec}->{$combat}) =
                $self->select_icons( spec => $spec, combat => $combat, f => $f );
        }
    }
    
    # find overlap between sets
    for my $name( qw|selected hidden| ) {
        # move same combat type in both specs to spec 0
        for my $combat( qw|in out| ) {
            $i{$name}->{0}->{$combat} = $i{$name}->{1}->{$combat} * $i{$name}->{2}->{$combat};
            $i{$name}->{1}->{$combat} -= $i{$name}->{0}->{$combat};
            $i{$name}->{2}->{$combat} -= $i{$name}->{0}->{$combat};
        }
        # move both combat types in a spec to either
        for my $spec( qw|0 1 2| ) {
            $i{$name}->{$spec}->{either} = $i{$name}->{$spec}->{in} * $i{$name}->{$spec}->{out};
            $i{$name}->{$spec}->{in} -= $i{$name}->{$spec}->{either};
            $i{$name}->{$spec}->{out} -= $i{$name}->{$spec}->{either};
        }
    }
    
    # get the icon objects for each group
    for my $name( qw|selected hidden| ) {
        for my $spec( qw|0 1 2| ) {
            for my $combat( qw|in out either| ) {
                my @set;
                for my $iname( $i{$name}->{$spec}->{$combat}->members ) {
                    my $icon = WoWUI::Module::TellMeWhen::Icons->instance->icon_get( $iname );
                    croak "can't find icon object for $iname" unless( $icon );
                    push @set, $icon->clone;
                }
                $i{$name}->{$spec}->{$combat} = [ sort {
                    $a->priority <=> $b->priority || $a->Name cmp $b->Name
                } @set ];
            }
        }
    }
    
    # for the out of combat groups, add a OOC condition and merge them into the either group
    my $ooc = WoWUI::Module::TellMeWhen::Condition->new( tag => 'ooc', Type => 'COMBAT', Level => 1 );
    for my $name( qw|selected hidden| ) {
        for my $spec( qw|0 1 2| ) {
            for my $icon( @{ $i{$name}->{$spec}->{out} } ) {
                my $has_cond = 0;
                for my $cond( $icon->cond_values ) {
                    if( 'ooc' eq $cond->tag ) {
                        $has_cond = 1, last;
                    }
                }
                unless( $has_cond ) {
                    $icon->unshift_cond( $ooc );
                }
                push @{ $i{$name}->{$spec}->{either} }, $icon;
            }
            delete $i{$name}->{$spec}->{out};
        }
    }

    # remove empty sets
    for my $name( qw|selected hidden| ) {
        for my $spec( qw|0 1 2| ) {
            for my $combat( qw|in out either| ) {
                unless( $i{$name}->{$spec}->{$combat} && @{ $i{$name}->{$spec}->{$combat} } ) {
                    $log->trace("removing empty set for $name $spec/$combat");
                    delete $i{$name}->{$spec}->{$combat};
                }
            }
        }
    }

    # report on what we've picked up
    for my $name( qw|selected hidden| ) {
        for my $spec( qw|0 1 2| ) {
            for my $combat( qw|in either| ) {
                if( $i{$name}->{$spec}->{$combat} ) {
                    $log->debug("post $desc $name for $spec/$combat: ",
                        join(':', map { $_->tag } @{ $i{$name}->{$spec}->{$combat} } ));
                }
            }
        }
    }
    
    # build groups
    my @group_order = qw|
        selected 1 in
        selected 0 in
        selected 1 either
        selected 0 either
        hidden 1 in
        hidden 0 in
        hidden 1 either
        hidden 0 either
        selected 2 in
        selected 2 either
        hidden 2 in
        hidden 2 either
    |;
    while( @group_order ) {
        my($name, $spec, $combat) = splice(@group_order, 0, 3);
        if( exists $i{$name}->{$spec}->{$combat} ) {
            $log->debug("building group for $name/$spec/$combat");
            my $group = WoWUI::Module::TellMeWhen::Group->new( modoptions => $self->modoptions );
            $group->populate( $self, \%i, $name, $spec, $combat );
        }
    }

    # if we have a rotation group, build it
    if( exists $self->modoptions->{rotation} ) {
        for my $spec( qw|1 2| ) {
            if( my $r = $self->modoptions->{rotation}->{"spec$spec"} ) {
                my $group = WoWUI::Module::TellMeWhen::Group::Rotation->new( modoptions => $self->modoptions );
                $group->populate( $self, $spec, $r );
            }
        }
    }

    # allow the icons to perform post-selection cleanup
    for my $group( @{ $self->Groups } ) {
        for my $icon( @{ $group->Icons } ) {
            $icon->fixup($self);
        }
    }
    
    # allow the groups to do post-population cleanup
    for my $group( @{ $self->Groups } ) {
        $group->fixup( $self );
    }
    
    # allow for binding text to be set per machine/player/realm/char
    for my $group( @{ $self->Groups } ) {
        for my $icon( @{ $group->Icons } ) {
            if( exists $self->modoptions->{bindtext}->{$icon->tag} ) {
                $icon->BindText( $self->modoptions->{bindtext}->{$icon->tag} );
            }
        }
    }

    # choose the group scale based on the widest group
    $self->groupscale( $config->{groupscale}->{$self->widestgroup} );
    for my $group( @{ $self->Groups } ) {
        $group->setscale( $self );
    }

}

sub select_icons
{

    my $self = shift;
    my %a = @_;
    my $char = $a{f}->char;

    my $log = WoWUI::Util->logger;
    
    my $desc = $char->rname;

    # get candidates from filter groups
    my $candidates = $self->filtergroups->candidates( $a{f} );
    $log->trace("candidates are $candidates");
    
    # create sets for selected and hidden icons
    my $selected = Set::Scalar->new;
    my $hidden = Set::Scalar->new;
    
    # if we don't have this spec, just return the empty sets
    unless( 0 == $a{spec} ) {
        unless( $char->spec_get($a{spec}) ) {
            return ($selected, $hidden);
        }
    }
    
    # iterate over candidates    
    my $using = 1 == $a{spec} ? F_C0|F_C1|F_MACH : F_C0|F_C2|F_MACH;
    for my $iname( $candidates->members ) {
        $log->trace("considering candidate $iname");
        my $icon = WoWUI::Module::TellMeWhen::Icons->instance->icon_get($iname);
        next if( $icon->combat && $a{combat} ne $icon->combat );
        if( $a{f}->match( $icon->filter, $using ) ) {
            $log->trace("selected $iname");
            $selected->insert( $iname );
            # allow the icon to select extra icons
            $icon->select_extra($hidden);
        }
    }
    if( $selected->size ) {
        $log->debug("pre $desc select $a{spec}/$a{combat}: $selected");
    }
    if( $hidden->size ) {
        $log->debug("pre $desc hidden $a{spec}/$a{combat}: $hidden");
    }

    return ($selected, $hidden);

}

sub augment_lua {

    return <<END;
            ["TextLayouts"] = {
                ["bar1"] = {
                    {
                    }, -- [1]
                    {
                    }, -- [2]
                },
                ["icon1"] = {
                    {
                    }, -- [1]
                    {
                    }, -- [2]
                },
            },
END
                                                                                                                                                                                                                                                        END
}

# keep require happy
1;

#
# EOF
