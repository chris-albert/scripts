#!/usr/bin/perl
use strict;
use warnings;

sub getFolderSize {
    my $path = shift;
    my $size = 0;
    
#    print "\n" . $path . "\n";
    
    opendir(IMD,$path) or die ("Dir $path doesnt exits!");
    my @dirs = readdir(IMD);
    foreach my $dir (@dirs) {
        unless($dir eq '.' || $dir eq '..') {
            if(-d "$path/$dir") {
                $size += getFolderSize("$path/$dir", $size);
            }else{
                $size += (-s "$path/$dir");
#                print "---" . $dir . "  " . (-s "$path/$dir") . "\n";
            }
        }
    }
#    print 'End Size: ' . $size . "\n\n";
    return $size;
}

sub readFile {
    my $path = shift;
    my $filename = shift;
    my $artist;
    my $album;
    my $count = 0;
    my $size = 0;
    my $total_size = 0;
    open FILE, "<" ,$filename or die $!;
    while (<FILE>) {
        chomp($_);
        if($_ =~ /^~(.*)/) {
            #if we have an album
            $album = $1;
            print " album: " . $album . "\n";
            $size += getFolderSize($path . "/$artist/$album");
        }elsif($_ =~ /^\*(.*)/) {
            $artist = $1;
            print '  Size: ' . $size . "\n";
            $total_size += $size;
            $size = getFolderSize($path . "/$artist");
            print "\n*artist: " . $artist . "\n";
            print '  *Size: ' . $size . "\n";
            $total_size += $size;
            $size = 0;
        }else {
            #if we have an artist
            $artist = $_;
            if($size) {
                print '  Size: ' . $size . "\n";
            }
            if($artist) {
                print "\nartist: " . $artist . "\n";
            }
            
            $total_size += $size;
            $size = 0;
        }

    }
    print "\nTotal Size: " . $total_size . "\n";
}

my $filename = "/media/data/Music";

print "Media Mover .1\n";
print "--------------\n";
#my $total_size = getFolderSize("/media/data/Music/Bayside");
#print "SIZE IN BYTES:     " . $total_size . "\n";
#print "SIZE IN MEGABYTES: " . (int(($total_size / 100000)) / 10) . "\n";
#print "SIZE IN GIGABYTES: " . (int(($total_size / 100000000)) / 10) . "\n";

readFile($filename,"/media/data/scripts/mediamover/media.txt");

