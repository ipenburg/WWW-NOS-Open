#!/usr/bin/perl -w    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

# $Id: TestNOSOpen.pl 405 2011-01-04 23:55:37Z roland $
# $Revision: 405 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/scripts/TestNOSOpen.pl $
# $Date: 2011-01-05 00:55:37 +0100 (Wed, 05 Jan 2011) $

use utf8;
use 5.006000;

our $VERSION = '0.01';

use CGI qw/:all/;
use HTTP::Server::Brick;

use lib q{../lib};
use Getopt::Long;
use Pod::Usage;
use WWW::NOS::Open;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $CONNECTOR_PORT => 8081;
Readonly::Scalar my $API_KEY        => $ENV{NOSOPEN_API_KEY} || q{TEST};
Readonly::Scalar my $TITLE          => q{NOS Open test page};
Readonly::Scalar my $EMPTY          => q{};
Readonly::Scalar my $ROOT           => q{/};
Readonly::Scalar my $SLASH          => q{/};

Readonly::Array my @GETOPT_CONFIG =>
  qw(no_ignore_case bundling auto_version auto_help);
Readonly::Array my @GETOPTIONS => ( q{port|p=s}, q{help|h}, q{verbose|v+}, );
Readonly::Hash my %OPTS_DEFAULT => ( port => $CONNECTOR_PORT, );
## use critic

Getopt::Long::Configure(@GETOPT_CONFIG);
my %opts = %OPTS_DEFAULT;
Getopt::Long::GetOptions( \%opts, @GETOPTIONS ) or Pod::Usage::pod2usage(2);

my $server = HTTP::Server::Brick->new( port => $opts{port} );
my $nos = WWW::NOS::Open->new($API_KEY);
my $nos_version =
  $nos->get_version->get_version . $SLASH . $nos->get_version->get_build;

$server->mount(
    $ROOT => {
        handler  => \&main,
        wildcard => 1,
    }
);

my $css = <<'EOC';
body {
    color: #000;
    background-color: #fff;
    font-family: Arial, sans-serif;
	font-size: 10px;
	width: 640px;
}

h1 {
	font-size: 16px;
}

h2 {
	font-size: 14px;
}

h3 {
	font-size: 12px;
}
EOC

sub main {
    my ( $req, $res ) = @_;
    my $uri = $req->uri;
    my $q   = CGI->new($uri);

    $res->add_content_utf8(
        $q->start_html(
            -title    => $q->escapeHTML($TITLE),
            -style    => { -code => $css },
            -encoding => q{utf-8},
        )
    );
    $res->add_content_utf8( $q->p( $q->escapeHTML($nos_version) ) );

    $res->add_content_utf8( $q->h1( $q->escapeHTML(q{Latest news articles}) ) );
    my @latest_articles = $nos->get_latest_articles(q{nieuws});
    while ( my $article = shift @latest_articles ) {
        $res->add_content_utf8(
            $q->h2(
                { -id => q{id} . $q->escapeHTML( $article->get_id ) },
                $q->escapeHTML( $article->get_title )
            )
        );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $article->get_description ) ) );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $article->get_published ) ) );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $article->get_last_update ) ) );
        $res->add_content_utf8(
            $q->a(
                { -href => $q->escapeHTML( $article->get_link ) },
                $q->img(
                    { -src => $q->escapeHTML( $article->get_thumbnail_xs ) }
                )
            )
        );
        $res->add_content_utf8(
            $q->a(
                { -href => $q->escapeHTML( $article->get_link ) },
                $q->img(
                    { -src => $q->escapeHTML( $article->get_thumbnail_s ) }
                )
            )
        );
        $res->add_content_utf8(
            $q->a(
                { -href => $q->escapeHTML( $article->get_link ) },
                $q->img(
                    { -src => $q->escapeHTML( $article->get_thumbnail_m ) }
                )
            )
        );
        if ( my @keywords = @{ $article->get_keywords } ) {
            $res->add_content_utf8(
                $q->ul( map { $q->li( $q->escapeHTML($_) ) } @keywords ) );
        }
    }

    $res->add_content_utf8( $q->h1( $q->escapeHTML(q{Latest news videos}) ) );
    my @latest_videos = $nos->get_latest_videos( $q->escapeHTML(q{nieuws}) );
    while ( my $video = shift @latest_videos ) {
        $res->add_content_utf8(
            $q->h2(
                { -id => q{id} . $q->escapeHTML( $video->get_id ) },
                $q->escapeHTML( $video->get_title )
            )
        );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $video->get_description ) ) );
        $res->add_content_utf8( $q->p( $video->get_embedcode ) );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $video->get_published ) ) );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $video->get_last_update ) ) );
        $res->add_content_utf8(
            $q->a(
                { -href => $q->escapeHTML( $video->get_link ) },
                $q->img(
                    { -src => $q->escapeHTML( $video->get_thumbnail_xs ) }
                )
            )
        );
        $res->add_content_utf8(
            $q->a(
                { -href => $q->escapeHTML( $video->get_link ) },
                $q->img(
                    { -src => $q->escapeHTML( $video->get_thumbnail_s ) }
                )
            )
        );
        $res->add_content_utf8(
            $q->a(
                { -href => $q->escapeHTML( $video->get_link ) },
                $q->img(
                    { -src => $q->escapeHTML( $video->get_thumbnail_m ) }
                )
            )
        );

        if ( my @keywords = @{ $video->get_keywords } ) {
            $res->add_content_utf8(
                $q->ul( map { $q->li( $q->escapeHTML($_) ) } @keywords ) );
        }
    }

    $res->add_content_utf8(
        $q->h1( $q->escapeHTML(q{Latest news audio fragments}) ) );
    my @latest_audio_fragments =
      $nos->get_latest_audio_fragments( $q->escapeHTML(q{nieuws}) );
    while ( my $audio_fragment = shift @latest_audio_fragments ) {
        $res->add_content_utf8(
            $q->h2(
                { -id => q{id} . $q->escapeHTML( $audio_fragment->get_id ) },
                $q->escapeHTML( $audio_fragment->get_title )
            )
        );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $audio_fragment->get_description ) ) );
        $res->add_content_utf8( $q->p( $audio_fragment->get_embedcode ) );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $audio_fragment->get_published ) ) );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $audio_fragment->get_last_update ) ) );
        $res->add_content_utf8(
            $q->a(
                { -href => $q->escapeHTML( $audio_fragment->get_link ) },
                $audio_fragment->get_thumbnail_s
                ? $q->img(
                    {
                        -src =>
                          $q->escapeHTML( $audio_fragment->get_thumbnail_s )
                    }
                  )
                : $q->escapeHTML( $audio_fragment->get_title )
            )
        );
        if ( my @keywords = @{ $audio_fragment->get_keywords } ) {
            $res->add_content_utf8(
                $q->ul( map { $q->li( $q->escapeHTML($_) ) } @keywords ) );
        }
    }

    my $result  = $nos->search(q{cricket});
    my @results = @{ $result->get_documents };
    my @related = @{ $result->get_related };
    while ( my $result = shift @results ) {
        $res->add_content_utf8(
            $q->h3( $q->escapeHTML( $result->get_title ) ) );
        $res->add_content_utf8(
            $q->p( $q->escapeHTML( $result->get_description ) ) );
    }
    while ( my $relation = shift @related ) {
        $res->add_content_utf8( $q->span( $q->escapeHTML($relation) ) );
    }

    my @tv_days = $nos->get_tv_broadcasts( q{2011-01-01}, q{2011-01-03} );
    while ( my $tv_day = shift @tv_days ) {
        $res->add_content_utf8( $q->h1( $q->escapeHTML( $tv_day->get_type ) ) );
        $res->add_content_utf8( $q->h2( $q->escapeHTML( $tv_day->get_date ) ) );
        my @broadcasts = @{ $tv_day->get_broadcasts };
        while ( my $broadcast = shift @broadcasts ) {
            $res->add_content_utf8(
                $q->h3( $q->escapeHTML( $broadcast->get_title ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_starttime ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_endtime ) ) );
            $res->add_content_utf8(
                $q->img(
                    {
                        -src => $q->escapeHTML( $broadcast->get_channel_icon ),
                        -alt => $q->escapeHTML( $broadcast->get_channel_name )
                    }
                )
            );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_channel_code ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_channel_name ) ) );
            $res->add_content_utf8(
                $q->h3( $q->escapeHTML( $broadcast->get_title ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_id ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_genre ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_description ) ) );
        }
    }
    my @radio_days = $nos->get_radio_broadcasts( q{2011-01-01}, q{2011-01-03} );
    while ( my $radio_day = shift @radio_days ) {
        $res->add_content_utf8(
            $q->h1( $q->escapeHTML( $radio_day->get_type ) ) );
        $res->add_content_utf8(
            $q->h2( $q->escapeHTML( $radio_day->get_date ) ) );
        my @broadcasts = @{ $radio_day->get_broadcasts };
        while ( my $broadcast = shift @broadcasts ) {
            $res->add_content_utf8(
                $q->h3( $q->escapeHTML( $broadcast->get_title ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_starttime ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_endtime ) ) );
            $res->add_content_utf8(
                $q->img(
                    {
                        -src => $q->escapeHTML( $broadcast->get_channel_icon ),
                        -alt => $q->escapeHTML( $broadcast->get_channel_name )
                    }
                )
            );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_channel_code ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_channel_name ) ) );
            $res->add_content_utf8(
                $q->h3( $q->escapeHTML( $broadcast->get_title ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_id ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_genre ) ) );
            $res->add_content_utf8(
                $q->p( $q->escapeHTML( $broadcast->get_description ) ) );
        }
    }

    $res->add_content_utf8( $q->end_html );

    $res->header( 'Content-Type', 'application/xhtml+xml; charset=utf-8' );
    return 1;
}

$server->start;

__END__

=encoding utf8

=for stopwords Roland van Ipenburg TestNOSOpen.pl

=head1 NAME

=head1 VERSION

This document describes C<TestNOSOpen.pl> version 0.01

=head1 USAGE

    ./TestNOSOpen.pl --apikey=APIKEY

=head1 REQUIRED ARGUMENTS

None.

=head1 OPTIONS

=over 4

=item B<--apikey> API key to use Open NOS

=back

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

L<CGI|CGI>
L<Getopt::Long|Getopt::Long>
L<HTTP::Server::Brick|HTTP::Server::Brick>
L<Pod::Usage|Pod::Usage>
L<Readonly|Readonly>

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<RT for rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-NOS-Open>.

=head1 DESCRIPTION

This starts an HTTP service which presents an HTML page that interacts with the Open NOS service.  For more information see:
L<http://open.nos.nl/|http://open.nos.nl/>

=head1 CONFIGURATION AND ENVIRONMENT

Using the defaults it starts the HTTP service on port 8081.

=head1 AUTHOR

Roland van Ipenburg  C<< <ipenburg@xs4all.nl> >>

=head1 LICENSE AND COPYRIGHT

    Copyright 2011 Roland van Ipenburg

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
