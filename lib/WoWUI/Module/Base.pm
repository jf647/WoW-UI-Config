#
# $Id: Base.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Base;
use Moose;
use MooseX::ABC;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;
use IPC::Run 'run';

# set up class
with 'WoWUI::ModOptions';
with 'WoWUI::ModConfig';
has name => ( is => 'rw', isa => 'Str' );
has [ qw|global globalpc perchar| ] => ( is => 'rw', isa => 'Bool', default => 0 );
has globaldata => (
    is => 'rw',
    isa => 'HashRef',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        has_globaldata => 'count',
        globaldata_exists => 'exists',
        globaldata_set => 'set',
        globaldata_get => 'get',
        globaldata_clear => 'clear',
    },
);
has perchardata => (
    is => 'rw',
    isa => 'HashRef',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        perchardata_set => 'set',
        perchardata_clear => 'clear',
        has_perchardata => 'count',
    },
);
has config => ( is => 'rw', isa => 'HashRef' );
has player => ( is => 'rw', isa => 'WoWUI::Player' );
has machine => ( is => 'rw', isa => 'WoWUI::Machine' );
CLASS->meta->make_immutable;

use Carp 'croak';
use Clone 'clone';
use Hash::Merge::Simple 'merge';
use File::Copy;

use WoWUI::Util qw|expand_path load_layered perchar_sv sv tempfile tt log tempdir|;
use WoWUI::Filter::Constants qw|F_MPR|;
use WoWUI::NoData;

# constructor
sub BUILD
{

    my $self = shift;

    my $gcfg = WoWUI::Config->instance->cfg;
    my $name = lc( ref $self );
    $name =~ s/^wowui::module:://;
    $self->name( $name );
    $self->config( load_layered( "$name.yaml", '$ADDONCONFDIR', '$PRIVADDONCONFDIR' ) );

    if( exists $self->config->{modoptions} ) {
        $self->set_modoptions( { modoptions => { $self->name => $self->config->{modoptions} } } );
    }

    return $self;
  
}

sub modconfig
{

    my $self = shift;
    my $char = shift;
    
    my $config = clone $self->config;

    my @things;
    if( defined $char ) {
        @things = ( $self, $self->machine, $self->player, $char->realm, $char );
    }
    else {
        @things = ( $self, $self->machine, $self->player );
    }
    for my $thing( @things ) {
        if( $thing->modconfig_exists( $self->name ) ) {
            $config = merge( $config, $thing->modconfig_get( $self->name ) );
        }
    }
    
    return $config;

}

sub modoptions
{

    my $self = shift;
    my $char = shift;

    my $options = {};
    my @things;
    if( defined $char ) {
        @things = ( $self, $self->machine, $self->player, $char->realm, $char );
    }
    else {
        @things = ( $self, $self->machine, $self->player );
    }
    for my $thing( @things ) {
        if( $thing->modoption_exists( $self->name ) ) {
            $options = merge( $options, $thing->modoption_get( $self->name ) );
        }
    }
    
    return $options;

}

sub process
{

    my $self = shift;

    my $config = $self->modconfig;
    my $log = WoWUI::Util->log( callingobj => $self );

    # clear out old data
    $self->globaldata_clear;

    if( $self->globalpc ) {
        $self->build_globalpc;
    }
    if( $self->perchar ) {
        for my $realm( $self->player->realms ) {
            for my $char( $realm->chars ) {
                my $f = WoWUI::Filter->new( char => $char, machine => $self->machine );
                if( exists $config->{perchar_filter} ) {
                    next unless( $f->match( $config->{perchar_filter} ) );
                }
                $log->debug("processing perchar for ", $char->rname);
                $self->build_perchar( $char, $f );
                next unless( $self->has_perchardata );
                $self->register_char( $char );
                $self->write_perchar( $char );
            }
        }
    }
    if( $self->global ) {
        $self->build_global;
    }
    if( $self->has_globaldata ) {
        $self->write_global;
    }
    

}

sub build_global
{

    my $self = shift;

    my $config = $self->modconfig;
    my $log = WoWUI::Util->log( callingobj => $self );

    $log->debug("processing global");

    if( exists $config->{filter} ) {
        my $f = WoWUI::Filter->new( machine => $self->machine );
        return unless( $f->match( $config->{filter}, F_MPR ) );
    }
    $self->augment_global();
    
}

sub build_globalpc
{

    my $self = shift;

    my $config = $self->modconfig;

    if( exists $config->{filter} ) {
        my $f = WoWUI::Filter->new( machine => $self->machine );
        return unless( $f->match( $config->{filter}, F_MPR ) );
    }

    my $log = WoWUI::Util->log( callingobj => $self );
    
    for my $realm( $self->player->realms ) {
        for my $char( $realm->chars ) {
            my $f = WoWUI::Filter->new( char => $char, machine => $self->machine );
            if( exists $config->{perchar_filter} ) {
                next unless( $f->match( $config->{perchar_filter} ) );
            }
            $log->debug("processing globalpc for ", $char->rname);
            $self->augment_globalpc($char, $f);
            $self->register_char( $char );
        }
    }

}

sub build_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    $self->perchardata_clear;
    $self->perchardata_set( realm => $char->realm->name, char => $char->name );
  
    $self->augment_perchar( $char, $f );

}

sub augment_global { confess "augment_global must be overridden" }
sub augment_globalpc { confess "augment_globalpc must be overridden" }
sub augment_perchar { confess "augment_perchar must be overridden" }

sub register_char
{

    my $self = shift;
    my $char = shift;
    my $value = shift;
    
    return if( exists $self->globaldata->{charlist}->{$char->realm->name}->{$char->name} );
    $self->globaldata->{charlist}->{$char->realm->name}->{$char->name} = $value || 1;

}

sub write_global
{

    my $self = shift;
  
    my $config = $self->modconfig;
  
    my $svdir = sv( $self->player );
    my $log = WoWUI::Util->log( callingobj => $self );

    my $tt = tt();
  
    $self->globaldata->{config} = $config;

    for my $template( keys %{ $config->{templates}->{global} } ) {
        my $infname = expand_path( $config->{templates}->{global}->{$template}->{input} );
        my $outfname = expand_path(
            $config->{templates}->{global}->{$template}->{output},
            account => $self->player->account,
        );
        my($tempfh, $tempfname) = tempfile( dir => $svdir );
        $tt->process( $infname->stringify, $self->globaldata, $tempfh )
            or croak $tt->error, "\n";
        $tempfh->close;
        rename($tempfname, $outfname)
            or croak "can't rename $tempfname to $outfname\n";
        if( $config->{templates}->{global}->{$template}->{pretty_print} ) {
            my $pp_outfname = expand_path(
                $config->{templates}->{global}->{$template}->{pp_output},
                account => $self->player->account,
            );
            $self->pretty_print_lua( $outfname, $pp_outfname, $config->{templates}->{global}->{$template}->{pp_varname} );
        }
    }
    if( exists $config->{copy} ) {
        for my $copy( keys %{ $config->{copy}->{global} } ) {
            my $src = expand_path( $config->{copy}->{global}->{$copy}->{from} ); 
            my $dst = expand_path( $config->{copy}->{global}->{$copy}->{to} );
            unless( -d $dst->parent ) {
                $dst->parent->mkpath( 0, 0755 );
            }
            copy( $src, $dst )
                or croak "can't copy $src to $dst: $!";
            my $prefix = tempdir();
            my $zipdst = $dst;
            $zipdst =~ s|^$prefix/||;
            WoWUI::ExtraFiles->instance->add($dst, $zipdst);
            $log->debug("copied $src to $zipdst");
        }
    }

}

sub write_perchar
{

  my $self = shift;
  my $char = shift;

  my $config = $self->modconfig;
  
  my $svdir = perchar_sv( $char );
  
  my $tt = tt();

  $self->perchardata->{config} = $config;

  for my $template( keys %{ $config->{templates}->{perchar} } ) {
    my $infname = expand_path( $config->{templates}->{perchar}->{$template}->{input} );
    my $outfname = expand_path(
      $config->{templates}->{perchar}->{$template}->{output},
      realm => $char->realm->name,
      char => $char->dirname,
      account => $self->player->account,
    );
    my($tempfh, $tempfname) = tempfile( dir => $svdir );
    $tt->process( $infname->stringify, $self->perchardata, $tempfh )
      or croak $tt->error, "\n";
    $tempfh->close;
    rename($tempfname, $outfname)
        or croak "can't rename $tempfname to $outfname\n";
    if( $config->{templates}->{perchar}->{$template}->{pretty_print} ) {
        my $pp_outfname = expand_path(
            $config->{templates}->{perchar}->{$template}->{pp_output},
            realm => $char->realm->name,
            char => $char->dirname,
            account => $self->player->account,
        );
        $self->pretty_print_lua( $outfname, $pp_outfname, $config->{templates}->{perchar}->{$template}->{pp_varname} );
    }
  }

  if( exists $config->{copy} ) {
      for my $copy( keys %{ $config->{copy}->{perchar} } ) {
          my $src = expand_path( $config->{copy}->{perchar}->{$copy}->{from} );
          my $dst = expand_path( $config->{copy}->{perchar}->{$copy}->{to} );
          unless( -d $dst->parent ) {
              $dst->parent->mkpath( 0, 0755 );
          }
          copy( $src, $dst )
              or croak "can't copy $src to $dst: $!";
          my $prefix = tempdir();
          my $zipdst = $dst;
          $zipdst =~ s|^$prefix/||;
          WoWUI::ExtraFiles->instance->add($dst, $zipdst);
          $self->debug("copied $src to $zipdst");
      }
  }
  
}

sub pretty_print_lua
{

    my $self = shift;
    my $outfname = shift;
    my $pp_outfname = shift;
    my $varname = shift;
    
    my $tt = tt();
    my $svdir = sv( $self->player );
    my $gcfg = WoWUI::Config->instance->cfg;
    
    # create the LUA program to run
    my($tempfh, $tempfname1) = tempfile( dir => $svdir );
    my $infname = expand_path( $gcfg->{pretty_print}->{template} );
    my $data = {
        outputfname => $outfname,
        pp_varname => $varname,
    };
    $tt->process( $infname->stringify, $data, $tempfh )
        or croak $tt->error, "\n";
    $tempfh->close;

    # use LUA to pretty print
    my(undef, $tempfname2) = tempfile( dir => $svdir );
    my @cmd = (
        $gcfg->{pretty_print}->{lua},
        $tempfname1,
    );
    run \@cmd, '>', $tempfname2->stringify
        or croak "can't run @cmd > $tempfname2!";
    rename($tempfname2, $pp_outfname)
        or croak "can't rename $tempfname2 to $outfname\n";
    unlink($tempfname1)
        or croak "can't unlink $tempfname1\n";

}

# keep require happy
1;

#
# EOF
