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

    my $log = WoWUI::Util->log;
    my $config = $self->config;

    # find the potential actions for this char
    my $candidates = $self->filtergroups->candidates($f);
    $log->trace("candidates are $candidates");

    for my $specnum( 1, 2 )  {

        # do they have this spec?
        my $spec = $char->spec_get( $specnum );
        my $all_settings;
        my $using;
        if( $spec ) {
            $chardata->{specs}->[$specnum]->{name} = $spec;
            if( 1 == $specnum ) {
                $using = F_C0|F_C1;
            }
            else {
                $using = F_C0|F_C2;
            }
        }
        else {
            $chardata->{specs}->[$specnum]->{name} = 'N/A';
            $using = F_CALL;
        }
        $all_settings = $self->get_all_settings( $f, $using );

        # populate values for settings based on flags
        my %values;
        for my $setting( $all_settings->members ) {
            if( exists $config->{settings}->{$setting}->{values} ) {
                $log->debug("getting value for $setting");
                my $value = $self->get_value(
                    $char,
                    $char->flags_get("spec${specnum}"),
                    $config->{settings}->{$setting}->{values},
                );
                if( defined $value ) {
                    $values{$setting} = $value;
                }
            }
        }
      
      # expand the values for our settings
      my $type = $self->machine->type;
      for my $block( "values_common", "values_spec${specnum}", "values_spec${specnum}_${type}" ) {
        if( exists $options->{$block} ) {
          for my $setting( @{ $options->{$block} } ) {
            for my $key( keys %$setting ) {
              $values{$key} = $setting->{$key};
            }
          }
        }
      }
      
      # every setting has to have a value or default
      my %settings;
      for my $setting( $all_settings->members ) {
        $settings{$setting} = {
          name => $setting,
          type => $config->{settings}->{$setting}->{type},
        };
        if( exists $values{$setting} ) {
          $log->trace("taking derived value for $setting: $values{$setting}");
          $settings{$setting}->{value} = $values{$setting};
        }
        elsif( exists $config->{settings}->{$setting}->{mydefault} ) {
          $log->trace("taking default value for $setting: $config->{settings}->{$setting}->{mydefault}");
          $settings{$setting}->{value} = $config->{settings}->{$setting}->{mydefault};
        }
        elsif( exists $config->{settings}->{$setting}->{corkdefault} ) {
          $log->trace("taking default value for $setting: $config->{settings}->{$setting}->{corkdefault}");
          $settings{$setting}->{value} = $config->{settings}->{$setting}->{corkdefault};
        }
        else {
          croak "no value or default for $setting for ", $char->rname;
        }
      }
      
      # remove settings with a default value
      $self->remove_defaults( \%settings );

      $chardata->{specs}->[$specnum]->{settings} = [ values %settings ];
      
    }

    return $chardata;

}

sub get_all_settings
{

  my $self = shift;
  my $char = shift;
  my $flags = shift;

  my $log = WoWUI::Util->log;

  my $config = $self->config;
  
  my $settings = Set::Scalar->new;
  my @candidates = WoWUI::Util::Filter::filter_groups( $flags, $config->{settingsgroups}, 'settings' );
  for my $setting( @candidates ) {
    $log->debug("matching $setting");
    if( WoWUI::Util::Filter::matches( $flags, $char, $config->{settings}->{$setting} ) ) {
      $settings->insert($setting);
    }
  }
  $log->debug("settings: $settings");
  
  return $settings;

}

sub remove_defaults
{

  my $self = shift;
  my $settings = shift;

  my $config = $self->config;

  for my $setting( keys %$settings ) {
    if( exists $config->{settings}->{$setting}->{corkdefault} ) {
      if( 'number' eq $config->{settings}->{$setting}->{type} ) {
        if( $settings->{$setting}->{value} == $config->{settings}->{$setting}->{corkdefault} ) {
          delete $settings->{$setting};
        }
      }
      else {
        if( $settings->{$setting}->{value} eq $config->{settings}->{$setting}->{corkdefault} ) {
          delete $settings->{$setting};
        }
      }
    }
  }

}

sub get_value
{

  my $self = shift;
  my $char = shift;
  my $flags = shift;
  my $values = shift;

  my $log = WoWUI::Util->log;
  
  my $value;
  $log->trace("flags: $flags");
  for my $v( @$values ) {
    if( WoWUI::Util::Filter::matches( $flags, $char, $v ) ) {
        $log->trace("matched value: $v->{value}");
        $value = $v->{value};
    }
  }
  
  return $value;

}

# keep require happy
1;

#
# EOF
