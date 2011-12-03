#!/usr/bin/perl
use strict;
use warnings;
use MusicObj;
use Util;

print "Processing.....\n";
my $path = "/media/data/Music";
#$path = "/home/creasetoph/shares/chris_home_server/media/data/Music";
#$path = "/home/creasetoph/Desktop/music";
my $music = MusicObj->init($path);
$music->printDirs();
#$music->fixBadDirStructure();
#$music->convertAllFiles();
#$music->dirTags();
#$music->deleteEmptyDirs();
#$music->dir2tags();
#$music->getNoMp3();
$music->findNoTags();
#$music->rename();
Util::printHash($music->getFileTypeCount());
print "\n";


