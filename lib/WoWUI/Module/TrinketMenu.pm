#
# $Id: TrinketMenu.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::TrinketMenu;
use Moose;
use MooseX::ClassAttribute;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
class_has parser => ( is => 'ro', isa => 'HTML::Parser', lazy_build => 1 );
class_has json => ( is => 'ro', isa => 'JSON::Any', lazy_build => 1 );
class_has mech => ( is => 'ro', isa => 'WWW::Mechanize', lazy_build => 1 );
class_has cache_loaded => ( is => 'ro', isa => 'Bool', default => 0 );
class_has [ qw|cache byname byid| ] => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
CLASS->meta->make_immutable;

use Carp 'croak';
use Clone 'clone';
use Text::Balanced qw|extract_bracketed|;
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util qw|load_file dump_file expand_path log|;

# constructor
sub BUILD
{

    my $self = shift;
  
    $self->global( 1 );
    $self->perchar( 1 );

    return $self;

}

sub augment_global
{

    my $self = shift;
    
    return 1;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $config = $self->modconfig( $char );
    my $o = $self->modoptions( $char );
    my $log = WoWUI::Util->log;

    my %trinketmenu;

    # get list of all trinket itemids
    my $all = Set::Scalar->new;
    for my $set( keys %{ $o } ) {
        for my $trinket( @{ $o->{$set} } ) {
            my $trinketdata = $self->trinket_by_name( $trinket );
            $all->insert( $trinketdata->{itemid} );
        }
    }

    # for each spec
    for my $set( keys %{ $o } ) {
        my $active = Set::Scalar->new;
        for my $trinket( @{ $o->{$set} } ) {
            my $trinketdata = $self->trinket_by_name( $trinket );
            if( 0 == $trinketdata->{passive} ) {
                $active->insert( $trinketdata->{itemid} );
            }
        }
        my $inactive = $all - $active;
        $trinketmenu{profiles}->{$set}->{name} = $set;
        my @active = sort { $self->byid->{$b}->{priority} <=> $self->byid->{$a}->{priority} } $active->members;
        my @inactive = sort { $self->byid->{$b}->{priority} <=> $self->byid->{$a}->{priority} } $inactive->members;
        push @{ $trinketmenu{profiles}->{$set}->{trinkets} }, map { { name => $self->byid->{$_}->{name}, itemid => $_ } } @active;
        push @{ $trinketmenu{profiles}->{$set}->{trinkets} }, { name => '---', itemid => 0 };
        push @{ $trinketmenu{profiles}->{$set}->{trinkets} }, map { { name => $self->byid->{$_}->{name}, itemid => $_ } } @inactive;
    }

    for my $itemid( $all->members ) {
        push @{ $trinketmenu{trinkets} }, {
            name => $self->byid->{$itemid}->{name},
            itemid => $itemid,
            passive => 1 == $self->byid->{$itemid}->{passive} ? 1 : 0,
            prefer => 1 == $self->byid->{$itemid}->{prefer} ? 1 : 0,
        };
    }
    
    $self->perchardata_set( trinketmenu => \%trinketmenu );

}

sub _build_parser
{

    require HTML::Parser;
    my $parser = HTML::Parser->new;
    $parser->marked_sections( 1 );
    $parser->report_tags( 'script' );
    
    return $parser;

}

sub _build_mech
{

    require WWW::Mechanize;
    return WWW::Mechanize->new;

}

sub _build_json
{

    require JSON::DWIW;
    JSON::DWIW->import;
    require JSON::Any;
    JSON::Any->import;
    return JSON::Any->new;

}

sub trinket_by_name
{

    my $self = shift;
    my $trinketname = shift;

    unless( $self->cache_loaded ) {
        $self->load_cache_from_file;
    }

    unless( exists $self->byname->{$trinketname} ) {
        $self->add_by_name( $trinketname );
    }
    return $self->byname->{$trinketname};

}

sub trinket_by_id
{

    my $self = shift;
    my $trinketid = shift;

    unless( $self->cache_loaded ) {
        $self->load_cache_from_file;
    }
    
    unless( exists $self->byid->{$trinketid} ) {
        $self->add_by_id( $trinketid );
    }
    return $self->byid->{$trinketid};

}

sub load_cache_from_file
{

    my $self = shift;
    my $config = $self->modconfig;

    my $cachefile = expand_path( $config->{cachefile} );
    if( -f $cachefile ) {
        $self->cache( load_file( $cachefile ) );
        $self->byname( clone $self->cache );
        for my $override( keys %{ $config->{overrides} } ) {
            if( exists $self->cache->{$override} ) {
                if( exists $config->{overrides}->{$override}->{priority} ) {
                    $self->byname->{$override}->{priority} = $config->{overrides}->{$override}->{priority};
                }
                if( exists $config->{overrides}->{$override}->{prefer} ) {
                    $self->byname->{$override}->{prefer} = 1;
                }
            }
        }
    }
    for my $trinket( keys %{ $self->byname } ) {
        $self->byid->{$self->byname->{$trinket}->{itemid}} = $self->byname->{$trinket};
    }

}

sub write_cache_to_file
{

    my $self = shift;
    my $config = $self->modconfig;
    
    my $cachefile = expand_path( $config->{cachefile} );
    dump_file( $cachefile, $self->byname );

}

sub add_by_name
{

    my $self = shift;
    my $trinketfull = shift;
    my $trinket = $trinketfull;

    my $config = $self->modconfig;
    my $log = WoWUI::Util->log;

    $log->info("fetching trinket info for '$trinketfull'");

    my $itemid;
    if( $trinket =~ m/^(.+)\s+#(\d+)$/ ) {
        $trinket = $1;
        $itemid = $2;
    }
      
    unless( $itemid ) {
        $itemid = $self->get_itemid($trinket);
    }

    my $passive = $self->is_trinket_passive($trinket, $itemid);
    my $ilevel = $self->get_item_level($trinket, $itemid);

    my $trinketdata = {
        name => $trinket,
        passive => $passive,
        itemid => $itemid,
        priority => $ilevel * 10,
        prefer => 0,
    };

    if( exists $config->{overrides}->{$trinketfull}->{priority} ) {
        $trinketdata->{priority} = $config->{overrides}->{$trinketfull}->{priority};
    }
    if( exists $config->{overrides}->{$trinketfull}->{passive} ) {
        $trinketdata->{passive} = $config->{overrides}->{$trinketfull}->{passive};
    }
    if( exists $config->{overrides}->{$trinketfull}->{prefer} ) {
        $trinketdata->{prefer} = 1;
    }

    $self->byname->{$trinketfull} = $trinketdata;
    $self->byid->{$itemid} = $trinketdata;
    $self->write_cache_to_file;
    
}

sub is_trinket_passive
{

    my $self = shift;
    my $name = shift;
    my $itemid = shift;

    my $log = WoWUI::Util->log;

    my $mech = $self->mech;
    $mech->get( "http://www.wowhead.com/item=$itemid" ) or die;
        
    my $passive = 1;
    my $found = 0;
    my $text_handler = sub {

        my $is_cdata = shift;
        my $text = shift;

        return unless( $text =~ m|_\[$itemid\]\.tooltip_enus = '(.+)';| );
        $found = 1;
        my $itemtext = $1;
        if( $itemtext =~ m/Use: / ) {
            $passive = 0;
        }

    };

    my $parser = $self->parser;
    $parser->handler( text => $text_handler, 'is_cdata, text' );
    $parser->parse($mech->content)->eof;
        
    unless( $found ) {
        croak "could not find trinket tooltip for item $itemid";
    }
        
    $log->debug("$name is ", $passive ? "passive" : "active");
    return $passive;

}

sub get_item_level
{

    my $self = shift;
    my $name = shift;
    my $itemid = shift;

    my $log = WoWUI::Util->log;

    my $itemlevel;
    my $text_handler = sub {

        my $is_cdata = shift;
        my $text = shift;

        return unless( $text =~ m|_\[$itemid\]\.tooltip_enus = '(.+)';| );
        my $itemtext = $1;
        if( $itemtext =~ m/Item Level (\d+)/ ) {
            $itemlevel = $1;
        }

    };

    my $parser = $self->parser;
    $parser->handler( text => $text_handler, 'is_cdata, text' );
    my $mech = $self->mech;
    $mech->get( "http://www.wowhead.com/item=$itemid" ) or die;
    $parser->parse($mech->content)->eof;
        
    unless( $itemlevel ) {
        croak "could not find itemlevel for item $itemid";
    }
        
    $log->debug("$name has item level ", $itemlevel);
    return $itemlevel;

}

sub get_itemid
{

    my $self = shift;
    my $name = shift;
        
    my $log = WoWUI::Util->log;

    my $hc = 0;
    my $rf = 0;
    if( $name =~ m/^(.+) \(Heroic\)$/ ) {
        $name = $1;
        $hc = 1;
    }
    if( $name =~ m/^(.+) \(Raid Finder\)$/ ) {
        $name = $1;
        $rf = 1;
    }

    my $json = $self->json;

    my $itemid;
    my $text_handler = sub {
        my $is_cdata = shift;
        my $text = shift;

        return unless( $text =~ m/g_items/ );
        return unless( $text =~ m|data: \[(.+)\]}\);|s );
        my $itemtext = $1;

        my $match;
        my $remainder;
        while( $itemtext ) {
            $itemtext =~ s/^,//;
            ($match, $remainder) = extract_bracketed($itemtext, '{}');
            last unless( $match );
            $itemtext = $remainder;
            #$match =~ s/"sourcemore":\[.+?\],/"sourcemore":0,/;
            $match =~ s/,firstseenpatch:\s*(\d+),/,"firstseenpatch":$1,/;
            $match =~ s/,cost:\[(\d+)\]}/,"cost":[$1]}/;
            my $data = $json->jsonToObj( $match );
            if( $hc ) {
                next unless( $data->{heroic} );
            }
            elsif( $rf ) {
                next unless( $data->{raidfinder} );
            }
            else {
                next if( exists $data->{heroic} );
            }
            $itemid = $data->{id};
            $log->debug("itemid for $name/$hc/$rf: $itemid");
            last;
        }
    };

    my $parser = $self->parser;
    $parser->handler( text => $text_handler, 'is_cdata, text' );
    my $mech = $self->mech;
    $mech->get( "http://www.wowhead.com/items=4.-4?filter=na=$name" ) or die;
    $parser->parse($mech->content)->eof;
     
    die "no results for '$name'" unless( $itemid );
    return $itemid;

}

sub add_by_id
{

    croak "add trinket by ID not yet implemented";

}

# keep require happy
1;

#
# EOF
