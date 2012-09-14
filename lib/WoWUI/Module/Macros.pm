package WoWUI::Module::Macros;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use CLASS;

# set up class
extends 'WoWUI::Module::Base';
has maxmacro => ( is => 'ro', isa => 'Int', default => 36 );
has gmacronum => ( is => 'rw', isa => 'Int', default => 1 );
CLASS->meta->make_immutable;

use Carp 'croak';

use WoWUI::Config;
use WoWUI::Filter::Constants;

# constructor
sub BUILD
{

    my $self = shift;
    
    $self->globalpc( 1 );
    $self->perchar( 1 );

    return $self;

}

sub augment_globalpc
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $config = $self->config;
    
    my $gdata = $self->globaldata;
    $gdata->{macros} //= [];
    
    for my $mn( keys %{ $config->{global_macros} } ) {
    
        next if( exists $gdata->{macronames}->{$mn} );

        my $macro = $config->{global_macros}->{$mn};    

        if( $f->match( $macro->{filter}, $F_CALL|$F_MACH ) ) {
        
            if( @{ $gdata->{macros} } >= $self->maxmacro ) {
                croak "too many global macros";
            }
        
            my $m = {
                name => $macro->{name} // $mn,
                number => $self->gmacronum,
                icon => $macro->{icon} // 'INV_Misc_QuestionMark',
                macro => $macro->{macro} // '',
            };
            
            push @{ $gdata->{macros} }, $m;
            $gdata->{macronames}->{$mn} = 1;
            $self->gmacronum( $self->gmacronum + 1 );
        
        }
        
    }
    

}

sub augment_perchar
{

    my $self = shift;
    my $char = shift;
    my $f = shift;

    my $config = $self->config;

    my $gdata = $self->globaldata;    
    my $pdata = $self->perchardata;
    $pdata->{macros} = [];
    my $pmacronum = 16777217;   # http://www.wowpedia.org/Macro
    
    for my $mn( keys %{ $config->{macros} } ) {
    
        next if( exists $gdata->{macronames}->{$mn} );

        my $macro = $config->{macros}->{$mn};
    
        if( $f->match( $macro->{filter}, $F_CALL|$F_MACH ) ) {
        
            if( @{ $pdata->{macros} } >= $self->maxmacro ) {
                croak "too many perchar macros for " . $char->dname;
            }
        
            my $m = {
                name => $macro->{name} // $mn,
                number => $pmacronum,
                icon => $macro->{icon} // 'INV_Misc_QuestionMark',
                macro => $macro->{macro} // '',
            };
            
            push @{ $pdata->{macros} }, $m;
            $pmacronum++;
        
        }
        
    }

}

# keep require happy
1;

#
# EOF
