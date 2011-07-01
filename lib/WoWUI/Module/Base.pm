#
# $Id: Base.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Base;
use Moose;

use namespace::autoclean;

# set up class
has 'name' => ( is => 'ro', isa => 'Str' );
has [ qw|global perchar| ] => ( is => 'ro', isa => 'Bool' );
has 'config' => ( is => 'rw', isa => 'HashRef' );
has 'options' => ( is => 'rw', isa => 'HashRef' );
has 'profile' => ( is => 'rw', isa => 'WoWUI::Profile' );
has 'extra_files' => (
    is => 'rw',
    isa => 'HashRef[Str]',
    traits => ['Hash'],
    required => 1,
    handles => {
        extra_file_add => 'set',
    },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use File::Copy;

use WoWUI::Util qw|expand_path load_layered perchar_sv sv tempfile tt log tempdir|;

# constructor
sub BUILD
{

  my $self = shift;

  my $gcfg = WoWUI::Config->instance->cfg;
  $self->config( load_layered( $self->name . '.yaml', '$ADDONCONFDIR', '$PRIVADDONCONFDIR' ) );
  
}

sub process_global
{

  my $self = shift;
  my $data = shift;
  
  my $config = $self->config;
  my $machine = WoWUI::Machine->instance;
  
  my $svdir = sv();
  my $log = WoWUI::Util->log;
  
  my $tt = tt();
  
  $data->{config} = $config;

  for my $template( keys %{ $config->{templates}->{global} } ) {
    my $infname = expand_path( $config->{templates}->{global}->{$template}->{input} );
    my $outfname = expand_path(
        $config->{templates}->{global}->{$template}->{output},
        account => $machine->account,
    );
    my($tempfh, $tempfname) = tempfile( dir => $svdir );
    $tt->process( $infname->stringify, $data, $tempfh )
      or croak $tt->error, "\n";
    $tempfh->close;
    rename($tempfname, $outfname)
        or croak "can't rename $tempfname to $outfname\n";
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
          $self->extra_file_add($dst, $zipdst);
          $log->debug("copied $src to $zipdst");
      }
  }

}

sub data
{

  my $self = shift;

  my $config = $self->config;

  if( exists $config->{criteria} ) {
    my $log = WoWUI::Util->log;
    my $flags = WoWUI::Machine->instance->flags + WoWUI::Profile->instance->flags;
    return unless( WoWUI::Util::Filter::matches( $flags, undef, $config->{criteria} ) );
  }
  inner();

}

sub chardata
{

  my $self = shift;
  my $char = shift;
  
  my $config = $self->config;

  my $log = WoWUI::Util->log;

  if( exists $config->{perchar_criteria} ) {
    return unless( WoWUI::Util::Filter::matches( $char->flags_get('all'), $char, $config->{perchar_criteria} ) );
  }
  inner($char);

}

sub process_perchar
{

  my $self = shift;
  my $char = shift;
  my $chardata = shift;

  my $config = $self->config;
  my $machine = WoWUI::Machine->instance;
  
  my $svdir = perchar_sv( $char->realm->name, $char->dirname );
  
  my $tt = tt();

  $chardata->{config} = $config;
  $chardata->{profile} = $self->profile;

  for my $template( keys %{ $config->{templates}->{perchar} } ) {
    my $infname = expand_path( $config->{templates}->{perchar}->{$template}->{input} );
    my $outfname = expand_path(
      $config->{templates}->{perchar}->{$template}->{output},
      realm => $char->realm->name,
      char => $char->dirname,
      account => $machine->account,
    );
    my($tempfh, $tempfname) = tempfile( dir => $svdir );
    $tt->process( $infname->stringify, $chardata, $tempfh )
      or croak $tt->error, "\n";
    $tempfh->close;
    rename($tempfname, $outfname)
        or croak "can't rename $tempfname to $outfname\n";
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
          $self->extra_file_add($dst, $zipdst);
          $self->debug("copied $src to $zipdst");
      }
  }
  
}

# keep require happy
1;

#
# EOF
