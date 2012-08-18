package WWW::NOS::Open;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

# $Id: Open.pm 414 2011-01-13 22:43:18Z roland $
# $Revision: 414 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/lib/WWW/NOS/Open.pm $
# $Date: 2011-01-13 23:43:18 +0100 (Thu, 13 Jan 2011) $

use utf8;
use 5.006000;

our $VERSION = '0.02';

use Date::Calc qw(Add_Delta_Days Date_to_Days Delta_Days Today);
use Date::Format;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Status
  qw(HTTP_OK HTTP_BAD_REQUEST HTTP_UNAUTHORIZED HTTP_FORBIDDEN HTTP_INTERNAL_SERVER_ERROR);
use JSON;
use LWP::UserAgent;
use Log::Log4perl qw(:easy get_logger);
use Moose qw/around has with/;
use Moose::Util::TypeConstraints qw/enum/;
use URI::Escape qw(uri_escape);
use URI;
use XML::Simple;

use namespace::autoclean -also => qr/^__/sxm;

use WWW::NOS::Open::Article;
use WWW::NOS::Open::AudioFragment;
use WWW::NOS::Open::Broadcast;
use WWW::NOS::Open::DayGuide;
use WWW::NOS::Open::Document;
use WWW::NOS::Open::Exceptions;
use WWW::NOS::Open::Result;
use WWW::NOS::Open::TypeDef;
use WWW::NOS::Open::Version;
use WWW::NOS::Open::Video;

use Readonly;
Readonly::Scalar my $SERVER => $ENV{NOSOPEN_SERVER} || q{http://open.nos.nl};
Readonly::Scalar my $TIMEOUT       => 15;
Readonly::Scalar my $AGENT         => q{WWW::NOS::Open/} . $VERSION;
Readonly::Scalar my $DATE_FORMAT   => q{%04u-%02u-%02u};
Readonly::Scalar my $DEFAULT_START => -1;                            # Yesterday
Readonly::Scalar my $DEFAULT_END   => 1;                             # Tomorrow
Readonly::Scalar my $MAX_RANGE     => 14;                            # Two weeks
Readonly::Scalar my $GET           => q{GET};
Readonly::Scalar my $DEFAULT_API_KEY  => q{TEST};
Readonly::Scalar my $DEFAULT_OUTPUT   => q{xml};
Readonly::Scalar my $DEFAULT_CATEGORY => q{nieuws};
Readonly::Scalar my $DASH             => q{-};
Readonly::Scalar my $DOUBLE_COLON     => q{::};
Readonly::Scalar my $FRAGMENT         => q{Fragment};
Readonly::Scalar my $VERSION_PATH => q{%s/v1/index/version/key/%s/output/%s/};
Readonly::Scalar my $LATEST_PATH =>
  q{%s/v1/latest/%s/key/%s/output/%s/category/%s/};
Readonly::Scalar my $SEARCH_PATH => q{%s/v1/search/query/key/%s/output/%s/q/%s};
Readonly::Scalar my $GUIDE_PATH =>
  q{%s/v1/guide/%s/key/%s/output/%s/start/%s/end/%s/};
Readonly::Scalar my $XML_DETECT    => qr{^<}smx;
Readonly::Scalar my $STRIP_PRIVATE => qr{^_}smx;

Readonly::Hash my %ERR => (
    INTERNAL_SERVER => q{Internal server error or no response recieved},
    UNPARSABLE      => q{Could not parse data},
    EXCEEDED_RANGE  => qq{Date range exceeds maximum of $MAX_RANGE days},
);
Readonly::Hash my %LOG => (
    REQUESTING    => q{Requesting %s},
    RESPONSE_CODE => q{Response code %d},
);

Log::Log4perl::easy_init($ERROR);

my $log = Log::Log4perl->get_logger(__PACKAGE__);

has '_ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub {
        LWP::UserAgent->new(
            timeout => $TIMEOUT,
            agent   => $AGENT,
        );
    },
);

has '_version' => (
    is  => 'ro',
    isa => 'WWW::NOS::Open::Version',
);

sub get_version {
    my $self = shift;
    my $url = sprintf $VERSION_PATH, $SERVER,
      URI::Escape::uri_escape( $self->get_api_key ),
      URI::Escape::uri_escape( $self->_get_default_output );
    my $response = $self->_do_request($url);
    my $version  = $self->_parse_version( $response->decoded_content );
    return $version;
}

sub _parse_version {
    my ( $self, $body ) = @_;
    my ( $version, $build );
    if ( $body =~ /$XML_DETECT/gsmx ) {
        my $xml = XML::Simple->new( ForceArray => 1 )->XMLin($body);
        $version = $xml->{item}[0]->{version}[0];
        $build   = $xml->{item}[0]->{build}[0];
    }
    else {
        $log->fatal( $ERR{UNPARSABLE} );
    }
    return WWW::NOS::Open::Version->new( $version, $build );
}

has '_default_output' => (
    is       => 'ro',
    isa      => 'Str',
    default  => $DEFAULT_OUTPUT,
    reader   => '_get_default_output',
    init_arg => 'default_output',
);

has '_api_key' => (
    is       => 'rw',
    isa      => 'Str',
    default  => $DEFAULT_API_KEY,
    reader   => 'get_api_key',
    writer   => 'set_api_key',
    init_arg => 'api_key',
);

sub _get_latest_resources {
    my ( $self, $type, $category ) = @_;
    ( defined $category ) || ( $category = $DEFAULT_CATEGORY );
    my $url = sprintf $LATEST_PATH,
      $SERVER,
      URI::Escape::uri_escape($type),
      URI::Escape::uri_escape( $self->get_api_key ),
      URI::Escape::uri_escape( $self->_get_default_output ),
      URI::Escape::uri_escape($category);
    my $response = $self->_do_request($url);
    my @resources =
      $self->_parse_resources( $type, $response->decoded_content );
    return @resources;
}

sub get_latest_articles {
    my ( $self, @param ) = @_;
    return $self->_get_latest_resources( q{article}, @param );
}

sub __get_props {
    my $meta = shift;
    my @props = map { $_->name } $meta->get_all_attributes;
    for (@props) {
        s/$STRIP_PRIVATE//smx;
    }
    return @props;
}

sub _parse_resource {
    my ( $self, $type, $hr_resource ) = @_;
    my %mapping = (
        article   => __PACKAGE__ . $DOUBLE_COLON . ucfirst $type,
        video     => __PACKAGE__ . $DOUBLE_COLON . ucfirst $type,
        audio     => __PACKAGE__ . $DOUBLE_COLON . ucfirst $type . $FRAGMENT,
        document  => __PACKAGE__ . $DOUBLE_COLON . ucfirst $type,
        broadcast => __PACKAGE__ . $DOUBLE_COLON . ucfirst $type,
    );

    my @props = __get_props( ( $mapping{$type} )->meta );
    my %param;
    while ( my $prop = shift @props ) {
        $param{$prop} =
          ( ref $hr_resource->{$prop}[0] eq q{HASH} )
          ? %{ $hr_resource->{$prop}[0] }
          : $hr_resource->{$prop}[0];
    }
    $param{keywords} = $hr_resource->{keywords}->[0]->{keyword} || [];
    if ( my $resource = ( $mapping{$type} )->new(%param) ) {
        return $resource;
    }
    return;
}

sub _parse_resources {
    my ( $self, $type, $body ) = @_;
    my @resources;

    if ( $body =~ /$XML_DETECT/gsmx ) {
        my $xml = XML::Simple->new( ForceArray => 1 )->XMLin($body);
        my @xml_resources = @{ $xml->{$type} };
        while ( my $resource = shift @xml_resources ) {
            push @resources, $self->_parse_resource( $type, $resource );
        }
        return @resources;
    }
    else {
        $log->fatal( $ERR{UNPARSABLE} );
    }
    return ();
}

sub get_latest_videos {
    my ( $self, @param ) = @_;
    return $self->_get_latest_resources( q{video}, @param );
}

sub get_latest_audio_fragments {
    my ( $self, @param ) = @_;
    return $self->_get_latest_resources( q{audio}, @param );
}

sub _parse_result {
    my ( $self, $body ) = @_;
    my @documents;
    if ( $body =~ /$XML_DETECT/gsmx ) {
        my $xml = XML::Simple->new( ForceArray => 1 )->XMLin($body);
        my @xml_documents = @{ $xml->{documents}->[0]->{document} };
        while ( my $hr_document = shift @xml_documents ) {
            push @documents,
              $self->_parse_resource( q{document}, $hr_document );
        }
        my $result = WWW::NOS::Open::Result->new(
            documents => [@documents],
            related   => $xml->{related}->[0]->{related},
        );
        return $result;
    }
    else {
        $log->fatal( $ERR{UNPARSABLE} );
    }
    return ();
}

sub search {
    my ( $self, $query ) = @_;
    my $url = sprintf $SEARCH_PATH,
      $SERVER,
      URI::Escape::uri_escape( $self->get_api_key ),
      URI::Escape::uri_escape( $self->_get_default_output ),
      URI::Escape::uri_escape($query);
    my $response = $self->_do_request($url);
    my $result   = $self->_parse_result( $response->decoded_content );
    return $result;
}

sub __get_date {
    my ( $start_day, $end_day ) = @_;
    my $today = Date_to_Days(Today);
    return (
        (
            sprintf $DATE_FORMAT,
            Add_Delta_Days( 1, 1, 1, $today + $start_day - 1 )
        ),
        (
            sprintf $DATE_FORMAT,
            Add_Delta_Days( 1, 1, 1, $today + $end_day - 1 )
        )
    );
}

sub _parse_dayguide {
    my ( $self, $hr_dayguide ) = @_;

    my @props = __get_props( WWW::NOS::Open::DayGuide->meta );
    my %param;
    while ( my $prop = shift @props ) {
        $param{$prop} =
          ( ref $hr_dayguide->{$prop} eq q{ARRAY} )
          ? (
            ( ref $hr_dayguide->{$prop}[0] eq q{HASH} )
            ? %{ $hr_dayguide->{$prop}[0] }
            : $hr_dayguide->{$prop}[0]
          )
          : $hr_dayguide->{$prop};
    }
    $param{broadcasts} = [];
    my @broadcasts = $hr_dayguide->{item};
    while ( my $ar_broadcast = shift @broadcasts ) {
        push @{ $param{broadcasts} },
          $self->_parse_resource( q{broadcast}, $ar_broadcast->[0] );
    }
    if ( my $dayguide = WWW::NOS::Open::DayGuide->new(%param) ) {
        return $dayguide;
    }
    return;
}

sub _parse_guide {
    my ( $self, $body ) = @_;
    my @dayguides;
    if ( $body =~ /$XML_DETECT/gsmx ) {
        my $xml = XML::Simple->new( ForceArray => 1 )->XMLin($body);
        my @xml_dayguides = @{ $xml->{dayguide} };
        while ( my $hr_dayguide = shift @xml_dayguides ) {
            push @dayguides, $self->_parse_dayguide($hr_dayguide);
        }
        return @dayguides;
    }
    else {
        $log->fatal( $ERR{UNPARSABLE} );
    }
    return ();
}

sub _get_broadcasts {
    my ( $self, $type, $start, $end, $channel ) = @_;

    my ( $default_start, $default_end ) =
      __get_date( $DEFAULT_START, $DEFAULT_END );
    ( defined $start ) || ( $start = $default_start );
    ( defined $end )   || ( $end   = $default_end );

    foreach ( $start, $end ) {
        ( ref $_ eq q{DateTime} ) && ( $_ = $_->ymd );
    }
    if ( Delta_Days( split /$DASH/smx, qq{$start$DASH$end} ) > $MAX_RANGE ) {
        ## no critic qw(RequireExplicitInclusion)
        NOSOpenExceededRangeException->throw(
            ## use critic
            error => $ERR{EXCEEDED_RANGE}
        );
    }
    my $url = sprintf $GUIDE_PATH,
      $SERVER,
      URI::Escape::uri_escape($type),
      URI::Escape::uri_escape( $self->get_api_key ),
      URI::Escape::uri_escape( $self->_get_default_output ),
      URI::Escape::uri_escape($start),
      URI::Escape::uri_escape($end);
    my $response   = $self->_do_request($url);
    my @guide_days = $self->_parse_guide( $response->decoded_content );
    return @guide_days;
}

sub get_tv_broadcasts {
    my ( $self, @param ) = @_;
    return $self->_get_broadcasts( q{tv}, @param );
}

sub get_radio_broadcasts {
    my ( $self, @param ) = @_;
    return $self->_get_broadcasts( q{radio}, @param );
}

sub _do_request {
    my ( $self, $url ) = @_;
    my $request = HTTP::Request->new(
        $GET => $url,
        HTTP::Headers->new(),
    );
    $log->debug( sprintf $LOG{REQUESTING}, $url );
    my $response = $self->_ua->request($request);
    $log->debug( sprintf $LOG{RESPONSE_CODE}, $response->code );
    if ( $response->code == HTTP_INTERNAL_SERVER_ERROR ) {
        ## no critic qw(RequireExplicitInclusion)
        NOSOpenInternalServerErrorException->throw(
            ## use critic
            error => $ERR{INTERNAL_SERVER}
        );
    }
    elsif ( $response->code > HTTP_OK ) {
        my $json = JSON->new;
        if ( $response->code == HTTP_BAD_REQUEST ) {
            ## no critic qw(RequireExplicitInclusion)
            NOSOpenBadRequestException->throw(
                ## use critic
                error => $json->decode( $response->decoded_content )
            );
        }
        elsif ( $response->code == HTTP_UNAUTHORIZED ) {
            ## no critic qw(RequireExplicitInclusion)
            NOSOpenUnauthorizedException->throw(
                ## use critic
                error => $json->decode( $response->decoded_content )
            );
        }
        elsif ( $response->code == HTTP_FORBIDDEN ) {
            ## no critic qw(RequireExplicitInclusion)
            NOSOpenForbiddenException->throw(
                ## use critic
                error => $json->decode( $response->decoded_content )
            );
        }
    }
    return $response;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my ( $api_key, $default_output ) = @_;

    return $class->$orig(
        api_key        => $api_key        || $DEFAULT_API_KEY,
        default_output => $default_output || $DEFAULT_OUTPUT,
    );
};

with 'WWW::NOS::Open::Interface';

no Moose;

## no critic qw(RequireExplicitInclusion)
__PACKAGE__->meta->make_immutable;
## use critic

1;

__END__

=encoding utf8

=for stopwords Roland van Ipenburg API NOS Readonly PHP JSON URI 
searchengine useragent DateTime XML

=head1 NAME

WWW::NOS::Open - Perl framework for the
L<Open NOS|http://open.nos.nl/> REST API.

=head1 VERSION

This document describes WWW::NOS::Open version 0.02.

=head1 SYNOPSIS

    use WWW::NOS::Open;
    my $nos = WWW::NOS::Open->new($API_KEY);
    @latest_articles = $nos->get_latest_articles('nieuws');

=head1 DESCRIPTION

Wrapper around the REST API to get data from Open NOS into Perl.

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new WWW::NOS::Open object.

=over

=item 1. The API key to use in the connection to the Open NOS service. You
need to L<register at Open NOS|http://open.nos.nl/registratie/> to get an API
key.

=back

=head2 C<get_version>

Gets the version of the REST API as a
L<WWW::NOS::Open::Version|WWW::NOS::Open::Version> object.

=head2 C<get_latest_articles>

Returns the ten most recent articles as an array of
L<WWW::NOS::Open::Article|WWW::NOS::Open::Article> objects.

=over

=item 1. The optional category of the requested articles, C<nieuws> or
C<sport>. Defaults to the category C<nieuws>.

=back

=head2 C<get_latest_videos>

Returns the ten most recent videos as an array of
L<WWW::NOS::Open::Video|WWW::NOS::Open::Video> objects.

=over

=item 1. The optional category of the requested videos, C<nieuws> or C<sport>.
Defaults to the category C<nieuws>.

=back

=head2 C<get_latest_audio_fragments>

Returns the ten most recent audio fragments as an array of
L<WWW::NOS::Open::AudioFragment|WWW::NOS::Open::AudioFragment> objects.

=over

=item 1. The optional category of the requested audio fragments, C<nieuws> or
C<sport>.  Defaults to the category C<nieuws>.

=back

=head2 C<search>

Search the searchengine from L<NOS|http://www.nos.nl> for keywords. Returns
a L<WWW::NOS::Open::Results|WWW::NOS::Open::Results> object with a maximum of
25 items.

=over

=item 1. The keyword or a combination of keywords, for example C<cricket>,
C<cricket AND engeland>, C<cricket OR curling>.

=back

=head2 C<get_tv_broadcasts>

Gets a collection of television broadcasts between two optional dates. Returns
an array of L<WWW::NOS::Open::DayGuide|WWW::NOS::Open::DayGuide> objects. The
period defaults to starting yesterday and ending tomorrow. The period has an
upper limit of 14 days. An C<NOSOpenExceededRangeException> is thrown when
this limit is exceeded.

=over

=item 1. Start date in the format C<YYYY-MM-DD> or as L<DateTime|DateTime>
object.

=item 2. End date in the format C<YYYY-MM-DD> or as L<DateTime|DateTime>
object.

=back

=head2 C<get_radio_broadcasts>

Gets a collection of radio broadcasts between two optional dates. Returns an
array of L<WWW::NOS::Open::DayGuide|WWW::NOS::Open::DayGuide> objects. The
period defaults to starting yesterday and ending tomorrow. The period has an
upper limit of 14 days. An C<NOSOpenExceededRangeException> is thrown when this
limit is exceeded.

=over

=item 1. Start date in the format C<YYYY-MM-DD> or as L<DateTime|DateTime>
object.

=item 2. End date in the format C<YYYY-MM-DD> or as L<DateTime|DateTime>
object.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module uses the environment variable C<NOSOPEN_SERVER> to specify a
server that is not the default Open NOS live server at
L<http://open.nos.nl|http://open.nos.nl>.

The useragent identifier used in the request to the REST API is
C<WWW::NOS::Open/0.01>.

=head1 DEPENDENCIES

L<Date::Calc|Date::Calc>
L<Date::Format|Date::Format>
L<HTTP::Headers|HTTP::Headers>
L<HTTP::Request|HTTP::Request>
L<HTTP::Status|HTTP::Status>
L<JSON|JSON>
L<LWP::UserAgent|LWP::UserAgent>
L<Log::Log4perl|Log::Log4perl>
L<Moose|Moose>
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>
L<Readonly|Readonly>
L<URI|URI>
L<URI::Escape|URI::Escape>
L<WWW::NOS::Open::Article|WWW::NOS::Open::Article>
L<WWW::NOS::Open::AudioFragment|WWW::NOS::Open::AudioFragment>
L<WWW::NOS::Open::Broadcast|WWW::NOS::Open::Broadcast>
L<WWW::NOS::Open::DayGuide|WWW::NOS::Open::DayGuide>
L<WWW::NOS::Open::Document|WWW::NOS::Open::Document>
L<WWW::NOS::Open::Exceptions|WWW::NOS::Open::Exceptions>
L<WWW::NOS::Open::Result|WWW::NOS::Open::Result>
L<WWW::NOS::Open::TypeDef|WWW::NOS::Open::TypeDef>
L<WWW::NOS::Open::Version|WWW::NOS::Open::Version>
L<WWW::NOS::Open::Video|WWW::NOS::Open::Video>
L<XML::Simple|XML::Simple>
L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

This module uses Log::Log4perl.

=head1 BUGS AND LIMITATIONS

Currently this module only uses the XML output of the Open NOS service and has
no option to use the JSON or serialized PHP formats. When the API matures the
other output options might be added and the content of the raw responses
exposed for further processing in an appropriate environment.

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
