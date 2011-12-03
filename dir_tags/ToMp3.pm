#!/usr/bin/perl
#This package takes care of converting files to mp3
#Author: creasetoph
#
use strict;
use warnings;
use Util;
use AudioTags;

package ToMp3;

sub init {
    my $class = shift;
    my $self = {
        bitrates    => [96,112,128,160,192,224,256,320],
        convertable => ['m4a','wav','wma','flac'],
        id3v2map    => {
            title   => 'TIT2',
            artist  => 'TPE1',
            album   => 'TALB',
            year    => 'TYER',
            track   => 'TRCK'
        },
        TAG         => AudioTags->init()
    };
    bless $self,$class;
    return $self;
}

sub convert {
    my $self = shift;
    my $filename = shift;
    my $tags = $self->{TAG}->getTags($filename);
    my $newname = '';
    if($tags) {
        $tags->{newname} = $self->getNewPath($tags);
        #print $newname, "\n";
        if($filename =~ /.mp3$/i) {
            return 2;
        }elsif ($filename =~ /.m4a$/i) {
            return $self->convertMP4($tags);
        }elsif ($filename =~ /.wma$/i) {
            return $self->convertWMA($tags);
        }elsif ($filename =~ /.flac$/i) {
            return $self->convertFLAC($tags);
        }elsif ($filename =~ /.wav$/i){
            return $self->convertWAV($tags);
        }
    }elsif(
        $filename =~ /.mp3$/i  || 
        $filename =~ /.m4a$/i  ||
        $filename =~ /.wma$/i  ||
        $filename =~ /.flac$/i ||
        $filename =~ /.wav$/i
    ) {
        return -1;
    }
    return -2;
}

sub convertMP4 {
    my $self = shift;
    my $tags = shift;
    my $cmd = "faad -o - \"$tags->{filename}\" | lame -h -b $tags->{bit} - \"$tags->{newname}\"";
    if(system($cmd) == 0){
        $self->{TAG}->setMp3Tags($tags);
        return 1;
    }
    return 0;
}

sub convertWMA {
    my $self = shift;
    my $tags = shift;
    my $cmd = "mplayer \"$tags->{filename}\" -ao pcm:file=\"temp.wav\"";
    my $ret = system($cmd);
    $cmd = "lame -h -b $tags->{bit} \"temp.wav\" \"$tags->{newname}\"";
    if(system($cmd) == 0){
        $self->{TAG}->setMp3Tags($tags);
        return 1;
    }
    return 0;
}

sub convertFLAC {
    my $self = shift;
    my $tags = shift;
    my $cmd = "flac -sdc \"$tags->{filename}\" | lame - \"$tags->{newname}\"";
    if(system($cmd) == 0){
        $self->{TAG}->setMp3Tags($tags);
        return 1;
    }
    return 0;
}

sub convertWAV {
    my $self = shift;
    my $tags = shift;
    my $cmd = "lame -V0 \"$tags->{filename}\" \"$tags->{newname}\"";
    print $cmd ."\n";
    if(system($cmd) == 0){
        $self->{TAG}->setMp3Tags($tags);
        return 1;
    }
    return 0;
}

sub formatFilename {
    my $self = shift;
    my $track = shift;
    my $title = shift;
    my $name = lc $title;
    $name =~ s/ /_/g;
    $name =~ s/\//\|/g;
    if($track) {
        $track =~ s/\/.*//g;
        if($track =~ m/^\d+$/) {
            $track = '0'. $track if int($track) < 10;
            return $track . '_' . $name;
        }else {
            return $name;
        }
    }else {
        return $name;
    }
    
}

sub getNewPath {
    my $self = shift;
    my $tags = shift;
    return File::Basename::dirname($tags->{filename}).'/'. $self->formatFilename($tags->{track},$tags->{title}) . ".mp3";
}

1;
