#
# $Id: Base.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Base;
use Moose;
use MooseX::ABC;
use MooseX::ClassAttribute;

use namespace::autoclean;

# set up class
class_has name => ( is => 'rw', isa => 'Str' );
class_has [ qw|global perchar| ] => ( is => 'rw', isa => 'Bool', default => 0 );
has config => ( is => 'rw', isa => 'HashRef' );
has player => ( is => 'rw', isa => 'WoWUI::Player', required => 1 );
has machine => ( is => 'rw', isa => 'WoWUI::Machine', required => 1 );
has modoptions => (
  is => 'bare',
  isa => 'HashRef',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    modoption_set => 'set',
    modoption_get => 'get',
    modoption_exists => 'exists',
    modoptions_list => 'keys',
    modoptions_values => 'values',
  },
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Hash::Merge::Simple 'merge';
use File::Copy;

use WoWUI::Util qw|expand_path load_layered perchar_sv sv tempfile tt log tempdir|;

# constructor
sub BUILD
{

    my $self = shift;

    my $gcfg = WoWUI::Config->instance->cfg;
    $self->config( load_layered( $self->name . '.yaml', '$ADDONCONFDIR', '$PRIVADDONCONFDIR' ) );

    $self->modoption_set( $self->name, $self->config->{modoptions} );

    return $self;
  
}

sub process_global
{

  my $self = shift;
  my $data = shift;
  
  my $config = $self->config;
  
  my $svdir = sv( $self->player );
  my $log = WoWUI::Util->log;
  
  my $tt = tt();
  
  $data->{config} = $config;

  for my $template( keys %{ $config->{templates}->{global} } ) {
    my $infname = expand_path( $config->{templates}->{global}->{$template}->{input} );
    my $outfname = expand_path(
        $config->{templates}->{global}->{$template}->{output},
        account => $self->player->account,
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
          WoWUI::ExtraFiles->instance->add($dst, $zipdst);
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
    # XXX
    # my $flags = $self->machine->flags + $WoWUI::Profile->instance->flags;
    my $flags = $self->machine->flags;
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
  
  my $svdir = perchar_sv( $char );
  
  my $tt = tt();

  $chardata->{config} = $config;

  for my $template( keys %{ $config->{templates}->{perchar} } ) {
    my $infname = expand_path( $config->{templates}->{perchar}->{$template}->{input} );
    my $outfname = expand_path(
      $config->{templates}->{perchar}->{$template}->{output},
      realm => $char->realm->name,
      char => $char->dirname,
      account => $self->player->account,
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
          WoWUI::ExtraFiles->instance->add($dst, $zipdst);
          $self->debug("copied $src to $zipdst");
      }
  }
  
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
            $options = merge( $options, $self->modoption_get( $self->name ) );
        }
    }
    
    return $options;

}


# keep require happy
1;

#
# EOF
