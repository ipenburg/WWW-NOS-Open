# $Id: 09_pod.t 376 2010-12-11 19:36:51Z roland $
# $Revision: 376 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/t/09_pod.t $
# $Date: 2010-12-11 20:36:51 +0100 (Sat, 11 Dec 2010) $

use Test::More;
eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;
all_pod_files_ok();
