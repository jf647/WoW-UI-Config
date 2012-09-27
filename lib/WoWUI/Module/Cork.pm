#
# $Id: Cork.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Cork;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

# set up class
extends 'WoWUI::Module::Base';
has filtergroups => (
    is  => 'rw',
    isa => 'WoWUI::FilterGroups',
);
CLASS->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use Clone 'clone';
use WoWUI::Config;
use WoWUI::Filter::Constants;
use WoWUI::FilterGroups;

# constructor
sub BUILD
{

    my $self = shift;

    $self->global(1);
    $self->perchar(1);

    my $config = $self->config;

    # build filter groups
    my $fgs =
      WoWUI::FilterGroups->new( $config->{filtergroups}, $config->{settings}, );
    $self->filtergroups($fgs);

    return $self;

}

sub augment_global
{

    my $self = shift;
    $self->globaldata( $self->modoptions );

    return;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my %chardata;

    for my $specnum ( 1, 2 ) {

        # do they have this spec?
        my $spec = $char->spec_get($specnum);
        my $using;
        if ($spec) {
            $chardata{specs}->[$specnum]->{name} = $spec;
            if ( 1 == $specnum ) {
                $using = F_C0 | F_C1 | F_MACH;
            }
            else {
                $using = F_C0 | F_C2 | F_MACH;
            }
        }
        else {
            $chardata{specs}->[$specnum]->{name} = 'N/A';
            $using = F_CALL | F_MACH;
        }
        $chardata{specs}->[$specnum]->{profile} =
          $self->get_settings_and_values( $f, $using );

    }

    $self->perchardata( \%chardata );

    return;

}

sub get_settings_and_values
{

    my $self  = shift;
    my $f     = shift;
    my $using = shift;

    my $mo = $self->modoptions( $f->char );

    my $config = $self->modconfig( $f->char );
    my $log    = WoWUI::Util->logger;

    my $candidates = $self->filtergroups->candidates( $f, $using );
    $log->debug("candidates are $candidates");

    my %profile;

    for my $setting ( $candidates->members ) {
        $log->debug("considering $setting");
        my $filter = $config->{settings}->{$setting}->{filter};
        if ( exists $mo->{filters} && exists $mo->{filters}->{$setting} ) {
            $filter = clone $filter;
            unshift @$filter, @{ $mo->{filters}->{$setting} };
        }
        if ( my $r = $f->match( $filter, $using ) ) {
            unless ( defined $r->value ) {
                croak "match but no value for ", $f->char->rname,
                  "; setting $setting";
            }
            $profile{$setting} = {
                name  => $setting,
                value => $r->value,
                type  => $config->{settings}->{$setting}->{type},
            };
        }
    }

    return \%profile;

}

# keep require happy
1;

#
# EOF
