#
# $Id: Util.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Util;
use base 'Exporter';

our @EXPORT = ();
our @EXPORT_OK = qw|
  expand_path
  tempdir
  tempfile
  load_file
  dump_file
  perchar_sv
  sv
  tt
  log
|;

use strict;
use warnings;

use FindBin;
use File::Temp;
use Carp 'croak';
use Path::Class qw|dir file|;
use YAML::Any   qw|LoadFile DumpFile|;
use Log::Log4perl;

my $dirs;
sub expand_path
{

    my $path = shift;
    my %extra = @_;

    unless( $dirs ) {
        require WoWUI::Config;
        my $gcfg = WoWUI::Config->instance->cfg;
        for my $dirtype( keys %{ $gcfg->{dirs} } ) {
            my $dir = $gcfg->{dirs}->{$dirtype};
            $dir =~ s/\$BINDIR/$FindBin::Bin/;
            $dirs->{uc $dirtype} = dir( $dir )->resolve;
        }
    }

    for my $dirtype( %$dirs ) {
        $path =~ s/\$$dirtype/$dirs->{$dirtype}/;
        if( %extra ) {
            while( my($k, $v) = each %extra ) {
                my $uc_k = uc $k;
                $path =~ s/\$$uc_k/$v/;
            }
        }
    }
  
    return -d $path ? dir( $path ) : file( $path );

}

sub load_file
{

    my $fname = shift;

    if( Log::Log4perl->initialized ) {
        my $log = Log::Log4perl->get_logger(__PACKAGE__);
        $log->debug("loading file $fname");
    }
  
    return LoadFile($fname);  

}

sub dump_file
{

    my $fname = shift;
    my $data = shift;
  
    return DumpFile($fname, $data);  

}

my $tempdir;
sub tempdir
{

    my $clean = shift;

    my $log = WoWUI::Util->log();

    return $tempdir if( $tempdir );

    my $cfg = WoWUI::Config->instance->cfg;
    my $base = expand_path('$TEMPBASE');
    if( $clean ) {
        while( my $dir = $base->next ) {
            next unless( -d $dir );
            next if( $dir eq $base || $dir =~ m/\.\.?$/ || $dir =~ m|/\.svn$| );
            $log->info("deleting $dir");
            $dir->rmtree(0);
        }
    }
    $tempdir = $dirs->{TEMPDIR} = dir( File::Temp::tempdir( DIR => $base, CLEANUP => $clean ) );
    $log->info("creating tempdir $tempdir");
    return $tempdir;

}

sub tempfile
{

    my %p = @_;
    $p{suffix} ||= '.lua';
    $p{dir} ||= tempdir();
  
    my($tempfh, $tempfname) = File::Temp::tempfile( DIR => $p{dir}, SUFFIX => $p{suffix}, UNLINK => 1 );
    return( $tempfh, file( $tempfname ) );

}

sub perchar_sv
{

    my $realm = shift;
    my $char = shift;
  
    my $machine = WoWUI::Machine->instance;
  
    my $tempdir = tempdir();

    my $realmdir = $tempdir->subdir('WTF')->subdir('Account')->subdir($machine->account)->subdir($realm);
    my $chardir= $realmdir->subdir($char);
    my $svdir = $chardir->subdir('SavedVariables');
    $svdir->mkpath(0) unless( -d $svdir );
  
    return $svdir;

}

sub sv
{

    my $tempdir = tempdir();
    my $machine = WoWUI::Machine->instance;
    my $svdir = $tempdir->subdir('WTF')->subdir('Account')->subdir($machine->account)->subdir('SavedVariables');
    $svdir->mkpath(0) unless( -d $svdir );
    return $svdir;

}

my $tt;
sub tt
{

    return $tt if( $tt );

    # create a template processor
    my $tt = Template->new(
        ABSOLUTE => 1,
        INCLUDE_PATH => expand_path( '$TEMPLATEDIR' ),
    ) or croak "can't create Template object";

    return $tt;

}

sub log
{

    my $class = shift;
    my %p = @_;
    
    my $caller;
    if( exists $p{stacksup} ) {
        $caller = caller($p{stacksup});
    }
    else {
        $caller = caller();
    }
    $caller =~ s/::/./g;
    $caller =~ tr/A-Z/a-z/;
    $caller =~ s/^wowui\.//;
    if( exists $p{prefix} ) {
        $caller = $p{prefix} . '.' . $caller;
    }

    return Log::Log4perl->get_logger($caller);

}

# keep require happy
1;

#
# EOF