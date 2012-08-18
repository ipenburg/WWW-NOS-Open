package WWW::NOS::Open::Version;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

# $Id: Version.pm 408 2011-01-06 20:53:25Z roland $
# $Revision: 408 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/lib/WWW/NOS/Open/Version.pm $
# $Date: 2011-01-06 21:53:25 +0100 (Thu, 06 Jan 2011) $

use utf8;
use 5.006000;

our $VERSION = '0.02';

use Moose qw/around has/;
use namespace::autoclean -also => qr/^__/sxm;

use Readonly;
Readonly::Scalar my $UNDER  => q{_};
Readonly::Scalar my $GETTER => q{get};

my @strings = qw(version build);
while ( my $string = shift @strings ) {
    has $UNDER
      . $string => (
        is       => 'ro',
        isa      => 'Str',
        reader   => $GETTER . $UNDER . $string,
        init_arg => $string,
      );
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my ( $version, $build ) = @_;
    return $class->$orig(
        version => $version,
        build   => $build,
    );
};

no Moose;

## no critic qw(RequireExplicitInclusion)
__PACKAGE__->meta->make_immutable;
## use critic

1;

__END__

=encoding utf8

=for stopwords Roland van Ipenburg API NOS

=head1 NAME

WWW::NOS::Open::Version - represents a version of the
L<Open NOS|http://open.nos.nl/> REST API.

=head1 VERSION

This document describes WWW::NOS::Open version 0.02.

=head1 SYNOPSIS

    use WWW::NOS::Open::Version;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new>

=over

=item 1. The version number as string, like 'v1'

=item 2. The build number as string, like '0.0.1'

=back

=head2 C<get_version>

Returns the version number as string.

=head2 C<get_build>

Returns the build number as string.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<Moose|Moose>
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
