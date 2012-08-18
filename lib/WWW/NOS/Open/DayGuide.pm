package WWW::NOS::Open::DayGuide;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

# $Id: DayGuide.pm 410 2011-01-13 20:39:07Z roland $
# $Revision: 410 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/lib/WWW/NOS/Open/DayGuide.pm $
# $Date: 2011-01-13 21:39:07 +0100 (Thu, 13 Jan 2011) $

use utf8;
use 5.006000;

our $VERSION = '0.02';

use Moose qw/around has with/;
use Moose::Util::TypeConstraints qw/enum/;
use namespace::autoclean -also => qr/^__/sxm;

use WWW::NOS::Open::TypeDef qw(NOSDateTime NOSURI);

use Readonly;
Readonly::Array my @GUIDE_TYPES => qw(tv radio);

has '_type' => (
    is       => 'ro',
    isa      => enum( [@GUIDE_TYPES] ),
    reader   => 'get_type',
    init_arg => 'type',
);

has '_date' => (
    is       => 'ro',
    isa      => NOSDateTime,
    coerce   => 1,
    reader   => 'get_date',
    init_arg => 'date',
);

has _broadcasts => (
    is       => 'ro',
    isa      => 'ArrayRef[WWW::NOS::Open::Broadcast]',
    reader   => 'get_broadcasts',
    init_arg => 'broadcasts',
);

no Moose;

## no critic qw(RequireExplicitInclusion)
__PACKAGE__->meta->make_immutable;
## use critic

1;

__END__

=encoding utf8

=for stopwords Roland van Ipenburg API NOS DateTime URI DayGuide

=head1 NAME

WWW::NOS::Open::DayGuide - Class representing a client side television or
radio program guide for a day in the L<Open NOS|http://open.nos.nl/> REST API.

=head1 VERSION

This document describes WWW::NOS::Open::DayGuide version 0.02.

=head1 SYNOPSIS

    use WWW::NOS::Open::DayGuide;

=head1 DESCRIPTION

This class represents a guide containing the broadcasts for a day as returned
in the television and radio guide list for one or several days.

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new WWW::NOS::Open::DayGuide object.

=over

=item 1. A hash containing the properties and their values.

=back

=head2 C<get_type>

Returns the type of the guide as string C<tv> or C<radio>.

=head2 C<get_date>

Returns the date of the guide as L<DateTime|DateTime> object.

=head2 C<get_broadcasts>

Returns the broadcasts for that day as a reference to an array of
L<WWW::NOS::Open::Broadcast|WWW::NOS::Open::Broadcast> objects.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<Moose|Moose>
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>
L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<RT for rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-NOS-Open>.

=head1 AUTHOR

Roland van Ipenburg  C<< <ipenburg@xs4all.nl> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
