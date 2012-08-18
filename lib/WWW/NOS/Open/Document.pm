package WWW::NOS::Open::Document;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

# $Id: Document.pm 414 2011-01-13 22:43:18Z roland $
# $Revision: 414 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/lib/WWW/NOS/Open/Document.pm $
# $Date: 2011-01-13 23:43:18 +0100 (Thu, 13 Jan 2011) $

use utf8;
use 5.006000;

our $VERSION = '0.02';

use Moose qw/has/;
use Moose::Util::TypeConstraints qw/enum/;
use namespace::autoclean -also => qr/^__/sxm;

use WWW::NOS::Open::TypeDef qw(NOSDateTime NOSURI);

use Readonly;
Readonly::Scalar my $UNDER         => q{_};
Readonly::Scalar my $GETTER        => q{get};
Readonly::Array my @CATEGORIES     => qw(Nieuws Sport);
Readonly::Array my @RESOURCE_TYPES => qw(artikel article video audio);

has '_id' => (
    is       => 'ro',
    isa      => 'Str',
    reader   => 'get_id',
    init_arg => 'id',
);

has '_score' => (
    is       => 'ro',
    isa      => 'Num',
    reader   => 'get_score',
    init_arg => 'score',
);

has '_type' => (
    is       => 'ro',
    isa      => enum( [@RESOURCE_TYPES] ),
    reader   => $GETTER . $UNDER . 'type',
    init_arg => 'type',
);

my @strings = qw(title description subcategory);
while ( my $string = shift @strings ) {
    has $UNDER
      . $string => (
        is       => 'ro',
        isa      => 'Str',
        reader   => $GETTER . $UNDER . $string,
        init_arg => $string,
      );
}

my @dates = qw(published last_update);
while ( my $date = shift @dates ) {
    has $UNDER
      . $date => (
        is       => 'ro',
        isa      => NOSDateTime,
        coerce   => 1,
        reader   => $GETTER . $UNDER . $date,
        init_arg => $date,
      );
}

my @uris = qw(thumbnail link);
while ( my $uri = shift @uris ) {
    has $UNDER
      . $uri => (
        is       => 'ro',
        isa      => NOSURI,
        coerce   => 1,
        reader   => $GETTER . $UNDER . $uri,
        init_arg => $uri,
      );
}

has '_category' => (
    is       => 'ro',
    isa      => enum( [@CATEGORIES] ),
    reader   => 'get_category',
    init_arg => 'category',
);

has '_keywords' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    reader   => 'get_keywords',
    init_arg => 'keywords',
);

no Moose;

## no critic qw(RequireExplicitInclusion)
__PACKAGE__->meta->make_immutable;
## use critic

1;

__END__

=encoding utf8

=for stopwords Roland van Ipenburg API NOS DateTime URL URI Readonly

=head1 NAME

WWW::NOS::Open::Document - Class representing a client side document in the
L<Open NOS|http://open.nos.nl/> REST API.

=head1 VERSION

This document describes WWW::NOS::Open::Document version 0.02.

=head1 SYNOPSIS

    use WWW::NOS::Open::Document;

=head1 DESCRIPTION

This class represents the documents that appear in the search results.

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new document object.

=over

=item 1. A hash containing the properties and their values.

=back

=head2 C<get_id>

Returns the id of the document as string.

=head2 C<get_type>

Returns the type of the document as string C<article>, C<artikel>, C<audio> or
C<video>.

=head2 C<get_title>

Returns the title of the document as string.

=head2 C<get_description>

Returns the description of the document as string.

=head2 C<get_published>

Returns the publishing date of the document as a L<DateTime|DateTime> object.

=head2 C<get_last_update>

Returns the date of the last update for the document as a L<DateTime|DateTime>
object.

=head2 C<get_thumbnail>

Returns the URL of the thumbnail for the document as an L<URI|URI> object.

=head2 C<get_link>

Returns the URL of the main document as an L<URI|URI> object. 

=head2 C<get_keywords>

Returns the list of keywords for the document as a reference to an array of
strings.

=head2 C<get_score>

Returns the score of the document as ranked in the results as a number.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>
L<Moose|Moose>
L<Readonly|Readonly>
L<WWW::NOS::Open::TypeDef|WWW::NOS::Open::TypeDef>
L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

Until the API settles the resource type supports both C<artikel> and
C<article> for an article type resource.

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
