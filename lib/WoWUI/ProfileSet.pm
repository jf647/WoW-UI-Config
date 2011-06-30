#
# $Id: ProfileSet.pm 5034 2011-06-28 18:13:59Z james $
#

package WoWUI::ProfileSet;
use Moose;

# set up class
has nameseq => (
  is => 'bare',
  isa => 'HashRef[Num]',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    nameseq_set => 'set',
    nameseq_get => 'get',
    nameseq_exists => 'exists',
    nameseqs_list => 'keys',
    nameseqs_values => 'values',
  },
);
has digests => (
  is => 'bare',
  isa => 'HashRef[Str]',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    digest_set => 'set',
    digest_get => 'get',
    digest_exists => 'exists',
    digests_list => 'keys',
    digests_values => 'values',
  },
);
has profiles => (
  is => 'bare',
  isa => 'HashRef[HashRef|Object]',
  traits => ['Hash'],
  default => sub { {} },
  handles => {
    profile_set => 'set',
    profile_get => 'get',
    profile_exists => 'exists',
    profiles_list => 'keys',
    profiles_values => 'values',
  },
);
__PACKAGE__->meta->make_immutable;

use Digest;
use YAML::Any 'Dump';

use WoWUI::Util;

# store or match/return a profile
sub store
{

    my $self = shift;
    my $profile = shift;
    my $name = shift || 'Profile';
    
    my $log = WoWUI::Util->log( stacksup => 1, prefix => 'profileset' );
    
    my $digest = $self->digest( $profile );
    $log->debug("profile digest is $digest");
    my $pname;
    if( $self->digest_exists( $digest ) ) {
        $pname = $self->digest_get( $digest );
        $log->debug("matches to existing profile $pname");
    }
    else {
        my $pnum = 1;
        if( $self->nameseq_exists($name) ) {
            $pnum = $self->nameseq_get($name) + 1;
        }
        $pname = "$name $pnum";
        $log->debug("storing new profile as $pname");
        $self->profile_set($pname, $profile);
        $self->digest_set( $digest, $pname);
        $self->nameseq_set($name, $pnum);
    }
    
    return $pname;

}

sub digest
{

    my $self = shift;
    my $profile = shift;
    
    my $ctx = Digest->new('MD5');
    $ctx->add( Dump($profile) );
    return $ctx->hexdigest;

}

# keep require happy
1;

#
# EOF
