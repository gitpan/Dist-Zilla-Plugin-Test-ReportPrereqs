use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.006008
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib  ) );
__DATA__
David
Golden
dagolden
Brendan
Byrd
Perl
Karen
Etheridge
ether
Kent
Fredric
kentfredric
Randy
Stauner
randy
Yanick
Champoux
yanick
lib
Dist
Zilla
Plugin
Test
ReportPrereqs
