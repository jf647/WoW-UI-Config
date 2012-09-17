#
# $Id: LuaDumper.pm 5015 2011-05-30 11:39:08Z james $
#

package WoWUI::LuaDumper;
use Moose;
use MooseX::StrictConstructor;

use CLASS;
use namespace::autoclean;
use strict;
use warnings;
use Modern::Perl '2013';

# set up class
CLASS->meta->make_immutable;

use Carp 'croak';

# dump Bool / Num / Int / Str
sub dumplua
{

    my $class = shift;
    my $obj   = shift;
    my $attr  = shift;

    my $aname  = $attr->name;
    my $reader = $attr->get_read_method;
    my $aval   = $obj->$reader;

    if ( !defined $aval ) {
        if ( $attr->is_required ) {
            croak "undefined value for required attribute $aname";
        }
    }
    else {
        my $aval2 = $class->rdump( $attr, $aval );
        if ( defined $aval2 ) {
            return qq|["$aname"] = $aval2,\n|;
        }
    }

    return;

}

# dump an attribute value recursively
sub rdump
{

    my $class = shift;
    my $attr  = shift;
    my $aval  = shift;

    # check if we have a moose attribute.
    if ( blessed $attr && $attr->isa('Moose::Meta::Attribute') ) {
        return $class->dump_moose_attribute( $attr, $aval );
    }

    # native types
    else {
        # HashRef
        given ( ref $aval ) {
            when ('HASH') {
                return $class->dump_hash($aval);
            }
            when ('ARRAY') {
                return $class->dump_array($aval);
            }
            when ('') {
                return $class->dump_scalar($aval);
            }
            default {
                return;
            }
        }
    }

    return;

}

sub dump_moose_attribute
{

    my $class = shift;
    my $attr  = shift;
    my $aval  = shift;

    my $tc = $attr->type_constraint;

    # we know how to handle Bool, Num and Str natively
    given ($tc) {
        when ( $_->is_a_type_of('Bool') ) {
            return defined $aval ? $aval ? 'true' : 'false' : 'nil';
        }
        when ( $_->is_a_type_of('Num') ) {
            return $aval;
        }
        when ( $_->is_a_type_of('Str') ) {
            return qq|"$aval"|;
        }
    }

    # we can ask dumpable things to dump themselves
    if ( blessed $aval && $aval->does('WoWUI::Module::TellMeWhen::Dumpable') ) {
        return '{ ' . $aval->lua . ' }';
    }

    # pure HashRef and ArrayRef we recurse into
    elsif ( $tc->is_a_type_of('HashRef') || $tc->is_a_type_of('ArrayRef') ) {
        my $aval2 = $class->rdump( undef, $aval );
        if ( defined $aval2 ) {
            return $aval2;
        }
        return;
    }

    # anything else we defer to the consuming class
    return;

}

sub dump_hash
{

    my $class = shift;
    my $aval  = shift;

    my $dval = '';
    my @pairs;
    if ( keys %$aval ) {
        while ( my ( $k, $v ) = each %$aval ) {
            my $v2 = $class->rdump( undef, $v );
            if ( defined $v2 ) {
                push @pairs, qq|["$k"] = $v2|;
            }
        }
        if (@pairs) {
            return '{ ' . join( ', ', @pairs ) . ' }';
        }
    }
    else {
        return '{ }';
    }

    return;

}

sub dump_array
{

    my $class = shift;
    my $aval  = shift;

    my $dval = '';
    my @elems;
    if (@$aval) {
        for my $v (@$aval) {
            my $v2;
            if ( blessed $v && $v->does('WoWUI::Module::TellMeWhen::Dumpable') )
            {
                $v2 = '{ ' . $v->lua . ' }';
            }
            else {
                $v2 = $class->rdump( undef, $v );
            }
            if ( defined $v2 ) {
                push @elems, $v2;
            }
        }
        if (@elems) {
            return '{ ' . join( ', ', @elems ) . ' }';
        }
    }
    else {
        return '{ }';
    }

    return;

}

my $qr_num = qr/^[-.\d]+$/x;

sub dump_scalar
{

    my $class = shift;
    my $aval  = shift;

    if ( $aval =~ $qr_num ) {
        return $aval;
    }
    else {
        return qq|"$aval"|;
    }

    return;

}

#keep require happy
1;

#
# EOF
