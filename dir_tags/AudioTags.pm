#!/usr/bin/perl
#This package takes care of anything to do with audio tags, setting and getting
#Author: creasetoph
#
#Required perl modules
#   MP3::Tag            http://search.cpan.org/~ilyaz/MP3-Tag-1.13/lib/MP3/Tag.pm
#   MP4::Info           http://search.cpan.org/~JHAR/MP4-Info-1.12/Info.pm
#   MP3::Info           http://search.cpan.org/~daniel/MP3-Info-1.24/Info.pm
#   Audio::WMA          http://search.cpan.org/~daniel/Audio-WMA-1.3/WMA.pm
#   Audio::FLAC::Header http://search.cpan.org/~daniel/Audio-FLAC-Header-2.4/Header.pm

use strict;
use warnings;
use Util;
use MP4::Info;
use MP3::Tag;
use MP3::Info;
use Audio::WMA;
use Audio::FLAC::Header;

package AudioTags;

sub init {
    my $class = shift;
    my $self = {
        bitrates    => [96,112,128,160,192,224,256,320],
        id3v2map    => {
            title   => 'TIT2',
            artist  => 'TPE1',
            album   => 'TALB',
            year    => 'TYER',
            track   => 'TRCK'
        }
    };
    MP3::Tag->config(write_v24 => 1);
    bless $self,$class;
    return $self;
}

sub getTags {
    my $self = shift;
    my $filename = shift;
    if($filename =~ /.mp3$/i) {
        return $self->getMP3Tags($filename);
    }elsif ($filename =~ /.m4a$/i) {
        return $self->getMP4Tags($filename);
    }elsif ($filename =~ /.wma$/i) {
        return $self->getWMATags($filename);
    }elsif ($filename =~ /.flac$/i) {
        return $self->getFLACTags($filename);
    }elsif ($filename =~ /.wav$/i) {
        return $self->getWAVTags($filename);
    }else {
        return 0;
    }
}

sub getMP3Tags {
    my $self = shift;
    my $filename = shift;
    if(-e $filename && !-d $filename) {
        my $mp3 = MP3::Tag->new($filename);
        my $mp3info = MP3::Info::get_mp3info($filename);
        my @arr = $mp3->autoinfo();
        return { 
            title  => $arr[0] || '',
            track  => $arr[1] || '',
            artist => $arr[2] || '',
            album  => $arr[3] || '',
            year   => $arr[5] || '',
            time   => $mp3info->{TIME} || '',
            type   => 'mp3',
            filename => $filename
        };
    }else {
        return 0;
    }
}

sub getMP4Tags {
    my $self = shift;
    my $filename = shift;
    my $mp4 = new MP4::Info $filename;
    if($mp4) {
        return {
            title   => $mp4->nam || '',
            artist  => $mp4->art || '',
            album   => $mp4->alb || '',
            year    => $mp4->day || '',
            track   => $mp4->trkn->[0] || '',
            bit     => $self->determinBitrate($mp4->bitrate) || '',
            time    => $mp4->time || '',
            type    => 'm4a',
            filename => $filename
        };
    }
}

sub getWMATags {
    my $self = shift;
    my $filename = shift;
    my $wma = Audio::WMA->new($filename);
    my $tags = $wma->tags();
    my $info = $wma->info();
    return {
        title   => $tags->{TITLE} || '',
        artist  => $tags->{AUTHOR} || '',
        album   => $tags->{ALBUMTITLE} || '',
        year    => '',
        track   => $tags->{TRACKNUMBER} || '',
        bit     => 320,
        time    => $self->calcTime($info->{playtime_seconds}) || '',
        type    => 'wma',
        filename => $filename
    };
}

sub getFLACTags {
    my $self = shift;
    my $filename = shift;
    my $flac = Audio::FLAC::Header->new($filename);
    my $tags = $flac->tags();
    my $info = $flac->info();
    return {
        title   => $tags->{title} || '',
        artist  => $tags->{artist} || '',
        album   => $tags->{album} || '',
        year    => $tags->{date} || '',
        track   => $tags->{tracknumber} || '',
        time    => $self->calcTime($flac->{trackTotalLengthSeconds}) || '',
        type    => 'flac',
        filename => $filename
    };
}

sub getWAVTags {
    my $self = shift;
    my $filename = shift;
    my @tags = split(/\//,$filename);
    my $size = @tags;
    $tags[$size - 1] =~ /(.*)\.wav/i;
    return {
        title   => $1 || '',
        artist  => $tags[$size - 3] || '',
        album   => $tags[$size - 2] || '',
        type    => 'wav',
        filename => $filename
    };
}

sub setMp3Tags {
    my $self = shift;
    my %tags = %{shift(@_)};
    if(%tags) {
        print $tags{newname} , "\n";
        my $mp3 = MP3::Tag->new($tags{newname});
        if($mp3) {
            my $id3v1 = $mp3->new_tag("ID3v1");
            my $id3v2 = $mp3->new_tag("ID3v2");
            for my $k  (keys %tags) {
                my $v = $tags{$k};
                $id3v1->{$k} = $v;
                if($self->{id3v2map}->{$k}) {
                    $id3v2->add_frame($self->{id3v2map}->{$k},$v);
                }
            }
            $id3v1->write_tag;
            $id3v2->write_tag;
        }
    }
}

sub calcTime {
    my $self = shift;
    my $secs = shift;
    my $mins = int($secs / 60);
    $secs = $secs % 60;
    $mins = '0' . $mins if $mins < 10;
    $secs = '0' . $secs if $secs < 10;
    return "$mins:$secs";
}

sub determinBitrate {
    my ($self,$bitrate) = @_;
    foreach my $i (@{$self->{bitrates}}) {
        if($bitrate < $i) {
            return $i;
        }
    }
}

1;
