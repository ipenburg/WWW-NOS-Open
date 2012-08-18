# $Id: 12_manifest.t 376 2010-12-11 19:36:51Z roland $
# $Revision: 376 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/t/12_manifest.t $
# $Date: 2010-12-11 20:36:51 +0100 (Sat, 11 Dec 2010) $

use Test::More;
eval "use Test::CheckManifest 1.01";
plan skip_all => "Test::CheckManifest 1.01 required for testing test coverage"
  if $@;
ok_manifest( { filter => [qr/(Debian_CPANTS.txt|\.(svn|bak))/] } );
