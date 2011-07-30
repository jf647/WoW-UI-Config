#
# $Id: LuaDumper.pm 5015 2011-05-30 11:39:08Z james $
#

package WoWUI::LuaDumper;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

# set up class
__PACKAGE__->meta->make_immutable;

use Carp 'croak';

# dump Bool / Num / Int / Str
sub dump
{

    my $class = shift;
    my $obj = shift;
    my $attr = shift;

    my $aname = $attr->name;
    my $reader = $attr->get_read_method;
    my $aval = $obj->$reader;
    if( ! defined $aval && $attr->is_required ) {
        croak "undefined value for required attribute $aname";
    }
    my $aval2 = $class->rdump($attr, $aval);
    if( defined $aval2 ) {
        return qq|["$aname"] = $aval2,\n|;
    }
    return undef;

}

# dump an attribute value recursively
my $qr_num = qr/^[-.\d]+$/;
sub rdump
{

    my $class = shift;
    my $attr = shift;
    my $aval = shift;

    # check if we have a moose attribute.
    if( blessed $attr && $attr->isa( 'Moose::Meta::Attribute' ) ) {
        my $tc = $attr->type_constraint;
        # we know how to handle Bool, Num and Str natively
        if( $tc->is_a_type_of('Bool') ) {
            return defined $aval ? $aval ? 'true' : 'false' : 'nil';
        }
        elsif( $tc->is_a_type_of('Num') ) {
            return $aval;
        }
        elsif( $tc->is_a_type_of('Str') ) {
            return qq|"$aval"|;
        }
        # we can ask dumpable things to dump themselves
        elsif( blessed $aval && $aval->does('WoWUI::Module::TellMeWhen::Dumpable') ) {
            return '{ ' . $aval->lua . ' }';
        }
        # pure HashRef and ArrayRef we recurse into
        elsif( $tc->is_a_type_of('HashRef') || $tc->is_a_type_of('ArrayRef') ) {
            my $aval2 = $class->rdump(undef, $aval);
            if( defined $aval2 ) {
                return $aval2;
            }
            return undef;
        }
        # anything else we defer to the consuming class
        return undef;
    }
    else {
        # HashRef
        if( 'HASH' eq ref $aval ) {
            my $dval = '';
            my @pairs;
            if( keys %$aval ) {
                while( my($k, $v) = each %$aval ) {
                    my $v2 = $class->rdump(undef, $v);
                    if( defined $v2 ) {
                        push @pairs, qq|["$k"] = $v2|;
                    }
                }
                if( @pairs ) {
                    return '{ ' . join(', ', @pairs) . ' }';
                }
            }
            else {
                return '{ }';
            }
            return undef;
        }
        # ArrayRef
        elsif( 'ARRAY' eq ref $aval ) {
            my $dval = '';
            my @elems;
            if( @$aval ) {
                for my $v( @$aval ) {
                    my $v2;
                    if( blessed $v && $v->does('WoWUI::Module::TellMeWhen::Dumpable') ) {
                        $v2 = '{ ' . $v->lua . ' }';
                    }
                    else {
                        $v2 = $class->rdump(undef, $v);
                    }
                    if( defined $v2 ) {
                        push @elems, $v2;
                    }
                }
                if( @elems ) {
                    return '{ ' . join(', ', @elems) . ' }';
                }
            }
            else {
                return '{ }';
            }
            return undef;
        }
        # Other ref
        elsif( ref $aval ) {
            return undef;
        }
        # Scalar
        else {
            if( $aval =~ $qr_num ) {
                return $aval;
            }
            else {
                return qq|"$aval"|;
            }
        }
        # anything else we defer to the consuming class
        return undef;
    }

}

#keep require happy
1;

#
# EOF
