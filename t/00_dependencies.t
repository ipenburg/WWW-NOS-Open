# $Id: 00_dependencies.t 382 2010-12-14 18:12:26Z roland $
# $Revision: 382 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/t/00_dependencies.t $
# $Date: 2010-12-14 19:12:26 +0100 (Tue, 14 Dec 2010) $

use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg =
'Author test. Set the environment variable TEST_AUTHOR to enable this test.';
    plan( skip_all => $msg );
}

eval "use Test::Dependencies exclude => [qw/ WWW::NOS /], style => q{heavy}";
plan skip_all => "Test::Dependencies required for testing dependencies" if $@;

TODO: {
    todo_skip q{Test::Dependencies can't do WWW::NOS::Open}, 1
      if 1;    #!-f q{META.yml};
    ok_dependencies();
}
