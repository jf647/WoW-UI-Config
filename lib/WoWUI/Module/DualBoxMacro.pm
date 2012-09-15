#
# $Id: DualBoxMacro.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::DualBoxMacro;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
has filtergroups => (
    is => 'rw',
    isa => 'WoWUI::FilterGroups',
);
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util qw|tt expand_path log|;
use WoWUI::Filter::Constants;
use WoWUI::FilterGroups;

# constructor
sub BUILD {

    my $self = shift;
    
    $self->perchar( 1 );
    
    my $config = $self->config;

    # build filter groups
    my $fgs = WoWUI::FilterGroups->new(
        $config->{filtergroups},
        $config->{buttons},
    );
    $self->filtergroups( $fgs );
    
    return $self;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $config = $self->modconfig( $char );
    
    # copy masters from NADTTrustList
    my $ntl = WoWUI::Modules->instance->module_get('WoWUI::Module::NADTTrustList');
    my $ntl_o = $ntl->modoptions( $char );
    my $masters = $ntl_o->{trust} || [];
    $masters = [ grep { $_ ne $char->name } @$masters ];
    $char->modoption_set( $self->name, { masters => $masters } );

    # walk through bars, picking up a button for each
    my @bars;
    my @buttons;
    for my $barname( keys %{ $config->{bars} } ) {
        my $bar = { name => $barname };
        for my $buttonpos( sort { $a <=> $b } keys %{ $config->{bars}->{$barname}->{buttons} } ) {
            my $button;
            my $match = $self->find_button(
                $char,
                $f,
                $config->{bars}->{$barname}->{buttons}->{$buttonpos}->{buttontype},
                $config->{bars}->{$barname}->{defaultunit},
            );
            if( $match ) {
                $button = $self->build_button(
                    name => $match,
                    char => $char,
                    hotkey => $config->{bars}->{$barname}->{buttons}->{$buttonpos}->{binding},
                    unit => $config->{bars}->{$barname}->{defaultunit},
                );
            }
            else {
                $button = { empty => 1 };
            }
            push @buttons, $button;
            my $button_i = scalar @buttons;
            push @{ $bar->{buttons} }, $button_i;
        }
        $bar->{button_i} = join( ';', grep { defined $_ } @{ $bar->{buttons} } );
        $bar->{autoHide} = exists $config->{bars}->{$barname}->{autohide} ? 1 : 0;
        if( exists $config->{bars}->{$barname}->{showifunit} ) {
            $bar->{unit} = $config->{bars}->{$barname}->{showifunit};
        }
        else {
            $bar->{unit} = 'player';
        }
        $bar->{x} = $config->{bars}->{$barname}->{x};
        $bar->{y} = $config->{bars}->{$barname}->{y};
        $bar->{anchor} = $config->{bars}->{$barname}->{anchor};
        $bar->{columns} = $config->{bars}->{$barname}->{columns};
        push @bars, $bar;
    }
    
    $self->perchardata_set( bars => \@bars );
    $self->perchardata_set( buttons => \@buttons );

}

sub find_button
{

    my $self = shift;
    my $char = shift;
    my $f = shift;
    my $buttontype = shift;
    my $unit = shift;

    my $config = $self->modconfig( $char );
    
    my $found = 0;
    my $match;
    my $using = F_CALL;
    if( $char->dualbox_spec ) {
        if( 1 == $char->dualbox_spec ) {
            $using = F_C0|F_C1;
        }
        else {
            $using = F_C0|F_C2;
        }
    }

    my $candidates = $self->filtergroups->candidates( $f, $using );
    for my $button( $candidates->members ) {
        my @extra = ( "dbmtype:$buttontype" );
        if( $unit ) {
            push @extra, "dbmunit:$unit";
        }
        if( $f->match( $config->{buttons}->{$button}->{filter}, $using, \@extra ) ) {
            if( $found ) {
                croak "buttontype '$buttontype' matched two buttons ($match and $button)";
            }
            $found = 1;
            $match = $button;
        }
    }

    return $match;

}

sub build_button
{

    my $self = shift;
    my %p = @_;
    my $buttonname = $p{name};
    my $char = $p{char};
    my $hotkey = $p{hotkey};

    my $config = $self->modconfig( $char );
    my $buttoncfg = $config->{buttons}->{$buttonname};

    my $button = {
        hotkey => $hotkey,
        hotkeytext => $self->make_hotkey_text($hotkey),
        note => $buttonname,
    };
    if( $buttoncfg->{icon} ) {
        $button->{icon} = $buttoncfg->{icon};
    }

    # what type of button?
    if( exists $buttoncfg->{macro} ) {
        unless( exists $buttoncfg->{ttprocess} ) {
            $button->{macro} = $buttoncfg->{macro};
            return $button;
        }
        my $macrotxt = $buttoncfg->{macro};
        my $outputtxt = '';
        my $tt = tt();
        my $o = $self->modoptions( $char );
        my $masters = $o->{masters};
        $tt->process(\$macrotxt, { masters => $masters }, \$outputtxt)
            or die "can't process macro: ", $tt->error;
        $button->{macro} = $outputtxt;
        $button->{name} = $buttoncfg->{name} || croak "no name for macro '$buttonname'";
        return $button;
    }
    elsif( exists $buttoncfg->{spell} ) {
        my $data = {};
        # directed at a unit?
        if( exists $buttoncfg->{unit} ) {
            $data->{unit} = $buttoncfg->{unit};
        }
        elsif( $p{unit} ) {
            $data->{unit} = $p{unit};
        }
        # single spell or sequence?
        if( 'ARRAY' eq ref $buttoncfg->{spell} ) {
            $data->{seq} = 1;
            $data->{spell} = $buttoncfg->{spell};
            $button->{name} = $buttoncfg->{name} || croak "no name for macro '$buttonname'";
        }
        else {
            $data->{spell} = $buttoncfg->{spell};
            $button->{name} = $self->make_short_name( $buttoncfg->{spell} );
        }
        # reset?
        if( exists $buttoncfg->{reset} ) {
            $data->{reset} = $buttoncfg->{reset};
        }
        # ooc alternative?
        if( exists $buttoncfg->{ooc} ) {
            if( exists $data->{seq} && 1 == $data->{seq} ) {
                croak "ooc alternative is incompatible with a spell sequence in $buttoncfg->{spell}";
            }
            $data->{ooc} = 1;
            $data->{ooc_spell} = $buttoncfg->{ooc};
        }
        # notarget?
        if( exists $buttoncfg->{notarget} ) {
            delete $data->{unit};
        }
        my $template = expand_path( $config->{buttontemplate} );
        my $outputtxt = '';
        my $tt = tt();
        $tt->process($template->stringify, $data, \$outputtxt)
            or die "can't process macro: ", $tt->error;
        $button->{macro} = $outputtxt;
        return $button;
    }  

}

sub make_hotkey_text
{

    my $self = shift;
    
    my $hotkey = shift;
    
    $hotkey =~ s/CTRL/c/;
    $hotkey =~ s/SHIFT/s/;
    $hotkey =~ s/-//g;
    
    return $hotkey;

}

sub make_short_name
{

    my $self = shift;
    
    my $spell = shift;
    
    my $short = $spell;
    $short =~ s/([\w])[\w]+\s?/$1/g;
    $short =~ s/\s//g;
    if( 1 == length($short) ) {
        $short = substr($spell,0,4);
    }
    
    return $short;

}

# keep require happy
1;

#
# EOF
