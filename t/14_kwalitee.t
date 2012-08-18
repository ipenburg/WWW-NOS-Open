# $Id: 14_kwalitee.t 376 2010-12-11 19:36:51Z roland $
# $Revision: 376 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/candi/trunk/WWW-NOS-Open/t/14_kwalitee.t $
# $Date: 2010-12-11 20:36:51 +0100 (Sat, 11 Dec 2010) $

use Test::More;

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [qw( -has_meta_yml)] );
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
