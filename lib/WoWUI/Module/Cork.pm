#
# $Id: Cork.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Cork;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS:

# set up class
extends 'WoWUI::Module::Base';
has filtergroups => (
    is => 'rw',
    isa => 'WoWUI::FilterGroups',
);
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Filter::Constants;

# constructor
CLASS->name( 'cork' );
sub BUILD
{

    my $self = shift;
    
    $self->global( 1 );
    $self->perchar( 1 );
    
    my $config = $self->config;

    # build filter groups
    my $fgs = WoWUI::FilterGroups->new(
        $config->{filtergroups},
        $config->{settings},
    );
    $self->filtergroups( $fgs );
    
    return $self;

}

sub augment_global
{

    my $self = shift;
    return $self->modoptions;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    for my $specnum( 1, 2 )  {

        my $profile;

        # do they have this spec?
        my $spec = $char->spec_get( $specnum );
        my $using;
        if( $spec ) {
            $self->chardata->{specs}->[$specnum]->{name} = $spec;
            if( 1 == $specnum ) {
                $using = F_C0|F_C1;
            }
            else {
                $using = F_C0|F_C2;
            }
        }
        else {
            $self->chardata->{specs}->[$specnum]->{name} = 'N/A';
            $using = F_CALL;
        }
        $profile->{$specnum} = $self->get_settings_and_values($f, $using);
      }
      
      $self->chardata = $profile;
      
    }

}

sub get_all_settings_and_values
{

    my $self = shift;
    my $f = shift;
    my $using = shift;

    my $modoptions = $self->modoptions( $f->char );

    my $config = $self->config;
    my $log = WoWUI::Util->log;

    my $candidates = $self->filtergroups->candidates( $f, $using );
    $log->debug("candidates are $candidates");

    my $profile;
 
    for my $setting( $candidates->members ) {
        $log->debug("considering $setting");
        # if there is no filter, then it's in
        if( exists $config->{settings}->{$setting}->{filter} ) {
          if( $f->match( $config->{settings}->{$setting}, $using );
              $settings->insert($setting);
          }
        }
        else {
            $settings->insert($setting);
        }
    }
    $log->debug("settings: $settings");
  
    return $settings;

}

# keep require happy
1;

#
# EOF
