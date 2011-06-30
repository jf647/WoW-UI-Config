#
# $Id: TrinketMenu.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::TrinketMenu;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
has [ 'trinkets' ] => ( is => 'rw', isa => 'HashRef' );
augment chardata => \&augment_chardata;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Text::Balanced qw|extract_bracketed|;
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util qw|load_file dump_file expand_path log|;

# constructor
sub BUILDARGS {
    my $class = shift;
    return { @_, name => 'trinketmenu', global => 0, perchar => 1 };
}
sub BUILD
{

  my $self = shift;

  $self->load_trinket_cache();

}

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $config = $self->config;
  my $co = $char->modoption_get($self->name);
  my $trinkets = $self->trinkets;

  my %trinketmenu;

  # get list of all trinket itemids
  my $all = Set::Scalar->new;
  for my $set( keys %{ $co } ) {
    for my $trinket( @{ $co->{$set} } ) {
      $all->insert( $trinkets->{byname}->{$trinket}->{itemid} );
    }
  }  

  # for each spec
  for my $set( keys %{ $co } ) {
    my $active = Set::Scalar->new;
    for my $trinket( @{ $co->{$set} } ) {
      if( 0 == $trinkets->{byname}->{$trinket}->{passive} ) {
        $active->insert( $trinkets->{byname}->{$trinket}->{itemid} );
      }
    }
    my $inactive = $all - $active;
    $trinketmenu{profiles}->{$set}->{name} = $set;
    my @active = sort { $trinkets->{byid}->{$b}->{priority} <=> $trinkets->{byid}->{$a}->{priority} } $active->members;
    my @inactive = sort { $trinkets->{byid}->{$b}->{priority} <=> $trinkets->{byid}->{$a}->{priority} } $inactive->members;
    push @{ $trinketmenu{profiles}->{$set}->{trinkets} }, map { { name => $trinkets->{byid}->{$_}->{name}, itemid => $_ } } @active;
    push @{ $trinketmenu{profiles}->{$set}->{trinkets} }, { name => '---', itemid => 0 };
    push @{ $trinketmenu{profiles}->{$set}->{trinkets} }, map { { name => $trinkets->{byid}->{$_}->{name}, itemid => $_ } } @inactive;
  }

  for my $itemid( $all->members ) {
    push @{ $trinketmenu{trinkets} }, {
      name => $trinkets->{byid}->{$itemid}->{name},
      itemid => $itemid,
      passive => 1 == $trinkets->{byid}->{$itemid}->{passive},
      prefer => 1 == $trinkets->{byid}->{$itemid}->{prefer},
    };
  }
  
  return { realm => $char->realm->name, char => $char->name, trinketmenu => \%trinketmenu };

}

sub load_trinket_cache
{

  my $self = shift;

  my $config = $self->config;
  my $cachefile = expand_path( $config->{cachefile} );
  my $data = { trinkets => {} };
  if( -f $cachefile ) {
    $data = load_file( expand_path( $config->{cachefile} ) );
  }
  
  my $log = WoWUI::Util->log;
  
  my $updated = 0;
  for my $trinket( keys %{ $data->{trinkets} } ) {
    unless( exists $data->{trinkets}->{$trinket}->{prefer} ) {
      $data->{trinkets}->{$trinket}->{prefer} = 0;
      $updated = 1;
    }
  }
  for my $realm( WoWUI::Profile->instance->realms_values ) {
    for my $char( $realm->chars_values ) {
      my $co = $char->modoption_get($self->name);
      for my $set( keys %$co ) {
        for my $trinket( @{ $co->{$set} } ) {
          unless( exists $data->{trinkets}->{$trinket} ) {
            $log->warn("Trinket '$trinket' not found in cache - pulling from Wowhead");
            $data->{trinkets}->{$trinket} = $self->fetch_trinket_info($trinket);
            $updated++;
          }
        }
      }
    }
  }
  
  if( $updated ) {
    dump_file( expand_path( $config->{cachefile} ), $data );
  }

  for my $override( keys %{ $config->{overrides} } ) {
    if( exists $data->{trinkets}->{$override} ) {
      if( exists $config->{overrides}->{$override}->{priority} ) {
        $data->{trinkets}->{$override}->{priority} = $config->{overrides}->{$override}->{priority};
      }
      if( exists $config->{overrides}->{$override}->{prefer} ) {
        $data->{trinkets}->{$override}->{prefer} = 1;
      }
    }
  }
    
  # pivot to provide by-item-id lookups
  my $cache = { byname => $data->{trinkets} };
  for my $trinket( keys %{ $data->{trinkets} } ) {
    $cache->{byid}->{$data->{trinkets}->{$trinket}->{itemid}} = $data->{trinkets}->{$trinket};
  }

  $self->trinkets( $cache );  

}

sub fetch_trinket_info
{

  my $self = shift;
  my $trinketfull = shift;
  my $trinket = $trinketfull;


  my $itemid;
  my $hc = 0;
  if( $trinket =~ m/^(.+)\s+#(\d+)$/ ) {
    $trinket = $1;
    $itemid = $2;
  }
  
  unless( $itemid ) {
    $itemid = $self->get_itemid($trinket);
  }

  my $passive = $self->is_trinket_passive($trinket, $itemid);
  my $ilevel = $self->get_item_level($trinket, $itemid);
  return {
      name => $trinket,
      passive => $passive,
      itemid => $itemid,
      priority => $ilevel * 10,
      prefer => 0,
  };
  
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
    if( $name =~ m/^(.+) \(Heroic\)$/ ) {
        $name = $1;
        $hc = 1;
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
            else {
                next if( exists $data->{heroic} );
            }
            $itemid = $data->{id};
            $log->debug("itemid for $name/$hc: $itemid");
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

my $parser;
sub parser
{

    unless( $parser ) {
        require HTML::Parser;
        $parser = HTML::Parser->new;
        $parser->marked_sections( 1 );
        $parser->report_tags( 'script' );
    }
    
    return $parser;

}

my $mech;
sub mech
{

  unless( $mech ) {
    require WWW::Mechanize;
    $mech = WWW::Mechanize->new;
  }
  
  return $mech;

}

my $json;
sub json
{

  unless( $json ) {
    require JSON::DWIW;
    JSON::DWIW->import;
    require JSON::Any;
    JSON::Any->import;
    $json = JSON::Any->new;
  }
  
  return $json;

}

# keep require happy
1;

#
# EOF
