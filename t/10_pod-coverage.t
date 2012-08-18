# $Id: 10_pod-coverage.t 376 2010-12-11 19:36:51Z roland $
# $Revision: 376 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/t/10_pod-coverage.t $
# $Date: 2010-12-11 20:36:51 +0100 (Sat, 11 Dec 2010) $

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
all_pod_coverage_ok( { also_private => [q{BUILD}] } );
