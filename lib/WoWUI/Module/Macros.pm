package WoWUI::Module::Macros;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

# set up class
extends 'WoWUI::Module::Base';
has maxmacro  => ( is => 'ro', isa => 'Int', default => 36 );
has gmacronum => ( is => 'rw', isa => 'Int', default => 1 );
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Util 'tt';
use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;

    $self->globalpc(1);
    $self->perchar(1);

    return $self;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my $config = $self->config;

    my $gdata = $self->globaldata;
    $gdata->{macros} //= [];

    for my $mn ( keys %{ $config->{global_macros} } ) {

        next if ( exists $gdata->{macronames}->{$mn} );

        my $macro = $config->{global_macros}->{$mn};

        if ( my $r = $f->match( $macro->{filter}, F_CALL | F_MACH ) ) {

            if ( @{ $gdata->{macros} } >= $self->maxmacro ) {
                croak "too many global macros";
            }

            my $m = {
                name => $r->value->{name} // $mn,
                number => $self->gmacronum,
                icon   => $r->value->{icon} // 'INV_Misc_QuestionMark',
                macro  => $r->value->{macro} // '',
            };

            push @{ $gdata->{macros} }, $m;
            $gdata->{macronames}->{$mn} = 1;
            $self->gmacronum( $self->gmacronum + 1 );

        }

    }

    return;

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f    = shift;

    my $config = $self->config;

    my $gdata = $self->globaldata;
    my $pdata = $self->perchardata;
    $pdata->{macros} = [];

    for my $mn ( keys %{ $config->{macros} } ) {

        unless ( exists $config->{macros}->{$mn}->{num} ) {
            croak "no macro num for $mn";
        }

        next if ( exists $gdata->{macronames}->{$mn} );

        my $macro = $config->{macros}->{$mn};

        if ( my $r = $f->match( $macro->{filter}, F_CALL | F_MACH ) ) {

            if ( @{ $pdata->{macros} } >= $self->maxmacro ) {
                croak "too many perchar macros for " . $char->dname;
            }

            my $mtext = $r->value->{macro} // '';
            if ( exists $r->value->{ttprocess} ) {
                my $tt = tt();
                my $ntl =
                  WoWUI::Modules->module_get('WoWUI::Module::NADTTrustList');
                my $mo = $ntl->modoptions($char);
                if ( exists $mo->{trust} ) {
                    my $mtext2 = '';
                    $tt->process( \$mtext, { masters => $mo->{trust} },
                        \$mtext2 )
                      or croak "can't process macro: ", $tt->error;
                    $mtext = $mtext2;
                }
            }

            my $m = {
                name => $r->value->{name} // $mn,
                number => $config->{macros}->{$mn}->{num},
                icon   => $r->value->{icon} // 'INV_Misc_QuestionMark',
                macro  => $mtext,
            };

            push @{ $pdata->{macros} }, $m;

        }

    }

    return;

}

# keep require happy
1;

#
# EOF
