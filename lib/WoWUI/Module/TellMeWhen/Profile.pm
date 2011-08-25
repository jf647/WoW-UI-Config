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
has tmw => ( is => 'ro', isa => 'WoWUI::Module::TellMeWhen', weak_ref => 1 );
has char => ( is => 'rw', isa => 'WoWUI::Char', required => 1 );
has nextgrouppos => ( is => 'rw', isa => 'WoWUI::Module::TellMeWhen::Point' );
has widestgroup => ( is => 'rw', isa => 'Num', default => 0 );
has groupscale => ( is => 'rw', isa => 'Num', default => 2 );
has Locked => ( is => 'rw', isa => 'Bool', default => 1, traits => ['Relevant'], relevant => 1 );
has Interval => ( is => 'rw', isa => 'Num', default => 1, traits => ['Relevant'], relevant => 1 );
has EffThreshold => ( is => 'rw', isa => 'Num', default => 15, traits => ['Relevant'], relevant => 1 );
has NumGroups => ( is => 'ro', isa => 'Num', traits => ['Relevant'], relevant => 1 );
around 'NumGroups' => sub { $_[1]->group_count };
has CDCOColor => (
    is => 'rw',
    isa => 'HashRef[Num]',
    default => sub { { r => 0, g => 1, b => 0, a => 1 } },
    traits => ['Relevant'],
    relevant => 1,
);
has CDSTColor => (
    is => 'rw',
    isa => 'HashRef[Num]',
    default => sub { { r => 1, g => 0, b => 0, a => 1 } },
    traits => ['Relevant'],
    relevant => 1,
);
has PRESENTColor => (
    is => 'rw',
    isa => 'HashRef[Num]',
    default => sub { { r => 1, g => 1, b => 1, a => 1 } },
    traits => ['Relevant'],
    relevant => 1,
);
has ABSENTColor => (
    is => 'rw',
    isa => 'HashRef[Num]',
    default => sub { { r => 1, g => 0.35, b => 0.35, a => 1 } },
    traits => ['Relevant'],
    relevant => 1,
);
has OORColor => (
    is => 'rw',
    isa => 'HashRef[Num]',
    default => sub { { r => 0.5, g => 0.5, b => 0.5, a => 1 } },
    traits => ['Relevant'],
    relevant => 1,
);
has OOMColor => (
    is => 'rw',
    isa => 'HashRef[Num]',
    default => sub { { r => 0.5, g => 0.5, b => 0.5, a => 1 } },
    traits => ['Relevant'],
    relevant => 1,
);
has TextureName => ( is => 'rw', isa => 'Str', default => 'Blizzard', traits => ['Relevant'], relevant => 1 );
has [ qw|DrawEdge TestOn MasterSound ReceiveComm| ] => (
    is => 'rw', isa => 'Bool', default => 0,
    traits => ['Relevant'], relevant => 1,
);
has [ qw|WarnInvalids BarGCD ClockGCD| ] => (
    is => 'rw', isa => 'Bool', default => 1,
    traits => ['Relevant'], relevant => 1,
);
has EditorScale => ( is => 'rw', isa => 'Num', default => 0.8, traits => ['Relevant'], relevant => 1 );
has CheckOrder => ( is => 'rw', isa => 'Num', default => -1, traits => ['Relevant'], relevant => 1 );
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

    my $o = $self->tmw->modoptions( $self->char );

    # set the update interval
    $self->Interval( $o->{interval} );

    # create a point for the first group
    $self->nextgrouppos( WoWUI::Module::TellMeWhen::Point->new( %{ $o->{anchor} } ) );

    return $self;

}

# populate a profile with groups
sub populate
{

    my $self = shift;
    my $f = shift;

    my $desc = $self->char->rname;
    
    my $config = $self->tmw->modconfig( $self->char );
    my $o = $self->tmw->modoptions( $self->char );
    my $log = WoWUI::Util->log;

    # select icons
    my %i;
    for my $spec( 1, 2 ) {
        for my $combat( qw|in out| ) {
            $log->debug("selecting icons for spec $spec combat $combat");
            ($i{selected}->{$spec}->{$combat}, $i{hidden}->{$spec}->{$combat}) =
                $self->select_icons( $spec, $combat, $f );
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
                    my $icon = $self->tmw->icons->icon_get( $iname );
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
                $icon->unshift_cond( $ooc );
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
            my $group = WoWUI::Module::TellMeWhen::Group->new( tmw => $self->tmw, profile => $self );
            $group->populate( \%i, $name, $spec, $combat );
        }
    }

    # if we have a rotation group, build it
    if( exists $o->{rotation} ) {
        for my $spec( qw|1 2| ) {
            if( my $r = $o->{rotation}->{"spec$spec"} ) {
                my $group = WoWUI::Module::TellMeWhen::Group::Rotation->new( tmw => $self->tmw, profile => $self );
                $group->populate( $spec, $r );
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
        $group->fixup;
    }

    # choose the group scale based on the widest group
    $self->groupscale( $config->{groupscale}->{$self->widestgroup} );
    for my $group( @{ $self->Groups } ) {
        $group->setscale;
    }

}

sub select_icons
{

    my $self = shift;
    my $spec = shift;
    my $combat = shift;
    my $f = shift;

    my $log = WoWUI::Util->log;
    
    my $desc = $self->char->rname;

    # get candidates from filter groups
    my $candidates = $self->tmw->filtergroups->candidates( $f );
    $log->trace("candidates are $candidates");
    
    # create sets for selected and hidden icons
    my $selected = Set::Scalar->new;
    my $hidden = Set::Scalar->new;
    
    # if we don't have this spec, just return the empty sets
    unless( 0 == $spec ) {
        unless( $self->char->spec_get($spec) ) {
            return ($selected, $hidden);
        }
    }
    
    # iterate over candidates    
    my $using = 1 == $spec ? F_C0|F_C1 : F_C0|F_C2;
    for my $iname( $candidates->members ) {
        $log->trace("considering candidate $iname");
        my $icon = $self->tmw->icons->icon_get($iname);
        next if( $icon->combat && $combat ne $icon->combat );
        if( $f->match( $icon->filter, $using ) ) {
            $log->trace("selected $iname");
            $selected->insert( $iname );
            # allow the icon to select extra icons
            $icon->select_extra($hidden);
        }
    }
    if( $selected->size ) {
        $log->debug("pre $desc select $spec/$combat: $selected");
    }
    if( $hidden->size ) {
        $log->debug("pre $desc hidden $spec/$combat: $hidden");
    }

    return ($selected, $hidden);

}

sub augment_lua { '' }

# keep require happy
1;

#
# EOF
