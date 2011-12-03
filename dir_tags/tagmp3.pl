#!/usr/bin/perl
use strict;
use warnings;
use MusicObj;
use Util;
use Getopt::Std;


my $filename = shift;
if($filename) {
    my $tags = AudioTags->init();
    my $tag = $tags->getTags($filename);
    print "Tags: \n-----\n";
    Util::printHash($tag);
    print "\n";
    my %args;
    getopt('AaTty', \%args);
    my %changes;
    if($args{A}) {
        $tag->{artist} = $args{A};
    }   
    if($args{a}) {
        $tag->{album} = $args{a};
    }
    if($args{T}) {
        $tag->{title} = $args{T};
    }
    if($args{t}) {
        $tag->{track} = $args{t};
    }
    if($args{y}) {
        $tag->{year} = $args{y};
    }
    
    if($tag) {
        $tag->{newname} = $filename;
        $tags->setMp3Tags($tag);
    }
    $tag = $tags->getTags($filename);
    print "\nNew Tags: \n---------\n";
    Util::printHash($tag);
    print "\n";
}else {
    print "You must enter a filename\n";
}
