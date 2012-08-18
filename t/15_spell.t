# $Id: 15_spell.t 376 2010-12-11 19:36:51Z roland $
# $Revision: 376 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/t/15_spell.t $
# $Date: 2010-12-11 20:36:51 +0100 (Sat, 11 Dec 2010) $

use strict;
use warnings;
use English;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg =
'Author test. Set the environment variable TEST_AUTHOR to enable this test.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Spelling required to check spelling of POD';
    plan( skip_all => $msg );
}

Test::Spelling::add_stopwords(<DATA>);
Test::Spelling::all_pod_files_spelling_ok();
__DATA__
Ipenburg
RT
rt
cpan
org
