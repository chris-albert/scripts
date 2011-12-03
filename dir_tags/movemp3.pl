#!/usr/bin/perl
use strict;
use warnings;
use MusicObj;
use Util;

my $path = shift;
print $path ."\n";

my $music = MusicObj->init($path);
$music->{basepath} = '/media/data/Music';
$music->{copy} = 1;
$music->fixBadDirStructure();

