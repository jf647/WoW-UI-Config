#
# $Id: Cork.pm 4998 2011-05-25 16:26:54Z james $
#

package WoWUI::Module::Cork;
use Moose;

use namespace::autoclean;

# set up class
extends 'WoWUI::Module::Base';
augment data => \&augment_data;
augment chardata => \&augment_chardata;
__PACKAGE__->meta->make_immutable;

use Carp 'croak';
use Set::Scalar;

use WoWUI::Config;
use WoWUI::Util 'log';

# constructor
sub BUILDARGS
{

    my $class = shift;
    return { @_, name => 'cork', global => 1, perchar => 1 };

}

sub BUILD
{

    my $self = shift;
    my $config = shift;
    
    WoWUI::Util::Filter::check_filter_groups( $config->{settingsgroups}, $config->{settings}, 'settings' );    

}

sub augment_data
{

    my $self = shift;
    # XXX
    return WoWUI::Machine->instance->modoption_get($self->name);

}

sub augment_chardata
{

  my $self = shift;
  my $char = shift;

  my $log = WoWUI::Util->log;

  my $config = $self->config;
  my $chardata = { realm => $char->realm->name, char => $char->name };
  my $options = $char->modoption_get($self->name);

  for my $specnum( 1, 2 )  {

    # do they have this spec?
    my $spec = $char->spec_get( $specnum );
    my $all_settings;
    if( $spec ) {
      $chardata->{specs}->[$specnum]->{name} = $spec;
      $all_settings = $self->get_all_settings( $char, $char->flags_get("spec${specnum}") );
    }
    else {
      $chardata->{specs}->[$specnum]->{name} = 'N/A';
      $all_settings = $self->get_all_settings( $char, $char->flags_get('all') );
    }

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
    # XXX
    my $type = WoWUI::Machine->instance->type;
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
        croak "no value or default for $setting for ", $char->name, " of ", $char->realm->name;
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
