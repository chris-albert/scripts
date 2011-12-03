#!/usr/bin/perl
#This is a script to clean up a music library, will convert all files to mp3 and put
#music in a dir structure of Artists/Album/Track and will make sure all mp3 tags are 
#correct.
#Author: creasetoph
#
#We need to follow these few steps to make our library organized
#1: get dir structure correct
#2: convert everything to mp3, and move other to backup dir
#3: put tags on mp3's according to dir structure
#to convert m4a to mp3 install faad and lame
#then use this cmd
#faad -o - input.m4a | lame -h -b 320 - out.mp3
#


use strict;
use warnings;
use AudioTags;
use ToMp3;
use Util;
use MP4::Info;
use MP3::Tag;
use File::Path;
use File::Copy;
use File::Basename;

package MusicObj;

sub init {
    my $class = shift;
    my $self = {
        path        => shift,
        basepath    => undef,
        dirs        => undef,
        noMp3       => undef,
        copy        => 0,
        file_bak    => '/home/creasetoph/MusicBackup3',
        log_file    => '/media/data/scripts/dir_tags/logs/log.txt',
        bitrates    => [96,112,128,160,192,224,256,320],
        convertable => ['m4a','wav','wma','flac'],
        errors      => [],
        warnings    => [],
        msg         => [],
        id3v2map    => {
            title   => 'TIT2',
            artist  => 'TPE1',
            album   => 'TALB',
            year    => 'TYER',
            track   => 'TRCK',
            time    => 'TLEN'
        },
        TAG         => AudioTags->init(),
        TOMP3       => ToMp3->init()
    };
    bless $self,$class;
    $self->setDirs();
    $self->findNoMp3();
    return $self;
}

sub getDirs {
    my $self = shift;
    my $path = $_[0] ? shift : $self->{path};
    opendir(IMD,$path) or die ("Dir $path doesnt exits!");
    my @dirs = readdir(IMD);
    @dirs = sort(@dirs);
    my %hash = ();
    foreach my $dir (@dirs) {
        unless($dir eq '.' || $dir eq '..') {
            if(-d "$path/$dir") {
                $hash{$dir} = $self->getDirs("$path/$dir");
            }else{
                $hash{$dir} = '';
            }
        }
    }
    return \%hash;
}

sub setDirs {
    my $self = shift;
    my $path = shift;
    $self->{dirs} = $self->getDirs($path);
}

sub printDirs {
    my $self = shift;
    Util::printHash($self->{dirs});
}

sub testTags {
    my $self = shift;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
                        my $tag = $self->{TAG}->getTags("$self->{path}/$artist/$album/$track");
                        if($tag) {
                            print "Tags for $self->{path}/$artist/$album/$track\n";
                            Util::printHash($tag);
                            print "\n";
                        }
                    }
                }
            }
        }
    }

}

sub findNoMp3 {
    my $self = shift;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
                        if($track =~ /\.([[:alnum:]]+)$/) {
                            $self->{nomp3}{$artist}{$album}{$1}++;
                        }
                    }
                }
            }
        }
    }
}

sub findBadDirStructure {
    my $self = shift;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                unless(ref($tracks) eq 'HASH') {
                    $self->{badfiles}{'album'}{$artist}{$album} = 1;
                }
            }
        }else {
            $self->{badfiles}{'artist'}{$artist} = 1;
        }
    }
}

sub fixBadDirStructure {
    my $self = shift;
    $self->findBadDirStructure();
    #move bad artists
    for my $k (keys %{$self->{badfiles}{artist}}) {
        $self->moveFile($self->{path} . '/' . $k);
    }
    #move bad artists
    for my $artist (keys %{$self->{badfiles}{album}}) {
        for my $i (keys %{$self->{badfiles}{album}{$artist}}) {
            $self->moveFile("$self->{path}/$artist/$i");
        }
    }
}

sub moveFile {
    my $self = shift;
    my $filename = shift;
    my $tags = $self->{TAG}->getTags($filename);
    if($tags) {
        if($tags->{album} && $tags->{artist} && $tags->{title} && $tags->{track}) {
            my $newpath = $self->pathFromTags($tags);
            $self->moveToDir($filename,$newpath);
        }else {
            $self->warn("Couldnt find tags for $filename, didnt move");
        }
    }else {
        $self->moveToBackupDir($filename);
    }
}

sub pathFromTags {
    my $self = shift;
    my $tags = shift;
    my $basepath = $self->{basepath} || $self->{path};
    my $newpath = "$basepath/$tags->{artist}/$tags->{album}/". $self->formatFilename($tags->{track},$tags->{title}) . '.' . $tags->{type};
    return $newpath;
}

#You must have run findNoMp3() first so the objects 'nomp3' property will be set
sub getFilesToCovert {
    my $self = shift;
    $self->setDirs();
    $self->findNoMp3();
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
                        my $file = "$self->{path}/$artist/$album/$track";
                        my $ret = $self->{TOMP3}->convert($file);
                        if($ret == 1) {
                            $self->moveToBackupDir($file);
                        }elsif($ret == 0) {
                            $self->error("Error in converting $file to mp3");
                        }elsif($ret == -1) {
                            $self->error("No tags found for $file");
                        }elsif($ret == -2) {
                            $self->moveToBackupDir($file);
                        }
                    }
                }
            }
        }
    }
    return [];
}

sub dirTags {
    my $self = shift;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
                        my $path = "$self->{path}/$artist/$album/$track";
                        my $tags = $self->{TAG}->getTags($path);
                        if($tags) {
                            if($tags->{artist} ne $artist || $tags->{album} ne $album) {
                                $self->moveFile($path);
                            }
                        }else {
                            $track =~ /^(\d*)\s(.*)\.(.*)$/g;
                            my $name = $2 || '';
                            my $num = $1 || '';
                            print "$path has no tags, creating them\n";
                            print "Artist: $artist\n";
                            print "Album: $album\n";
                            print "Track: $name\n";
                            print "Num: $num\n";
                        }
                    }
                }
            }
        }
    }
}

sub deleteEmptyDirs {
    my $self = shift;
    my $path = '';
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        $path = "$self->{path}/$artist";
        if(ref($albums) eq 'HASH') {
            if(keys(%$albums) == 0) {
                File::Path::rmtree($path);
            }
            while(my ($album,$tracks) = each(%$albums)) {
                $path = "$self->{path}/$artist/$album";
                if(ref($tracks) eq 'HASH') {
                    if(keys(%$tracks) == 0) {
                       File::Path::rmtree($path);
                    }
                }
            }
        }
    }
}

sub convertAllFiles {
    my $self = shift;
    my @files = @{$self->getFilesToCovert()};
}

sub moveToDir {
    my $self = shift;
    my $filename = shift;
    my $newpath = shift;
    File::Path::mkpath(File::Basename::dirname($newpath));
    if($self->{copy}) {
        File::Copy::copy($filename,$newpath);
        $self->msg("Copied $filename to $newpath");
    }else {
        File::Copy::move($filename,$newpath);
        $self->msg("Moved $filename to $newpath");
    }
}

sub moveToBackupDir {
    my $self = shift;
    my $filename = shift;
    my $newPath = $filename;
    $newPath =~ s/$self->{path}//g;
    $newPath = $self->{file_bak} . $newPath;
    my $path = File::Basename::dirname($newPath);
    #create path to backup if it doesnt exist
    File::Path::mkpath($path);
    #print "Moving $filename to $newPath\n";
    if($self->{copy}) {
        File::Copy::copy($filename,$newPath);  
        $self->msg("Copied $filename to backup dir"); 
    }else {
        File::Copy::move($filename,$newPath);
        $self->msg("Moved $filename to backup dir");
    }
}

sub formatFilename {
    my $self = shift;
    my $track = shift;
    my $title = shift;
    my $name = lc $title;
    $track =~ s/\/.*//g;
    $name =~ s/ /_/g;
    $name =~ s/\//\|/g;
    if($track =~ m/^\d+$/) {
        $track = '0'. int($track) if $track < 10;
        return $track . '_' . $name;
    }else {
        return $name;
    }
}

sub deleteNonMp3 {
    my $self = shift;
    my %hash;
    if($self->{nomp3}) {
        while (my ($artist,$albums) = each(%{$self->{nomp3}})) {
            if(ref($albums) eq 'HASH') {
                while(my ($album,$types) = each(%$albums)) {
                    if(ref($types) eq 'HASH') {
                        while(my ($type,$count) = each(%$types)) {
                            unless(lc($type) eq 'mp3') {
                                while(my $track = each(%{$self->{dirs}{$artist}{$album}})) {
                                    if(lc($track) =~ /\.$type$/i) {
                                        #print "$self->{path}/$artist/$album/$track" , "\n";
                                        $self->moveToBackupDir("$self->{path}/$artist/$album/$track");
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }else {
        print "You need to call findNoMp3() before calling this func!\n";
    }
}

sub dir2tags {
    my $self = shift;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            print $artist . "\n";
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
#                        print $artist . " - " . $album . " - " . $track . "\n";
                    }
                }
            }
        }
    }
}

sub getFileTypeCount {
    my $self = shift;
    my %hash;
    if($self->{nomp3}) {
        while (my ($artist,$albums) = each(%{$self->{nomp3}})) {
            if(ref($albums) eq 'HASH') {
                while(my ($album,$types) = each(%$albums)) {
                    if(ref($types) eq 'HASH') {
                        while(my ($type,$count) = each(%$types)) {
                            unless($hash{$type}) {
                                $hash{$type} = 0;            
                            }
                            $hash{$type} = $hash{$type} + $count;
                        }
                    }
                }
            }
        }
        return \%hash;
    }
}

sub getNoMp3 {
    my $self = shift;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
                        if($track =~ /\.([[:alnum:]]+)$/) {
                            if($1 ne 'mp3') {
                                print $artist . '/' . $album . '/' . $track . ' *** ' . $1 ."\n";
                            }
                        }
                    }
                }
            }
        }
    }
}

sub findNoTags {
    my $self = shift;
    my $no_track = 0;
    my $no_title = 0;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
                        my $path = $self->{path} . '/' . $artist . '/' . $album . '/' . $track;
                        my $tags = $self->{TAG}->getTags($path);
#                        print "Path: " .$path ."\n";
#                        Util::printHash($tags);
#                        print "\n\n";
                        if($tags) {
                            if($tags->{artist} ne $artist || $tags->{album} ne $album) {
                                $self->msg("Retaging {" . $tags->{artist} . '} to {' . $artist . '}');
                                $self->{TAG}->setMp3Tags({
                                    newname => $path,
                                    artist  => $artist,
                                    album   => $album
                                });
                            }
#                            if($tags->{title} ne $track) {
#                                print $tags->{title} . ' is not equal to ' . $track ."\n";
#                            }
                            if($tags->{title} eq '') {
                                print $path . " has no title set\n";
                                $no_title++;
                            }
                            if($tags->{track} eq '') {
#                                print $path . " has no track set\n";
                                print $path ."\n";
                                print 'Enter Track Num: ';
                                my $track = <>;
                                system('./tagmp3.pl "' . $path . "\" -t " . $track);
                                $no_track++;
                            }
                        }else {
                            $self->msg("Tagging {" . $artist . '}');
                            $self->{TAG}->setMp3Tags({
                                newname => $path,
                                artist  => $artist,
                                album   => $album
                            });
                        }
                    }
                }
            }
        }
    }
    print "No Title Set: " . $no_title . "\n";
    print "No Track Set: " . $no_track . "\n";
}

sub rename {
 my $self = shift;
    while (my ($artist,$albums) = each(%{$self->{dirs}})) {
        if(ref($albums) eq 'HASH') {
            while(my ($album,$tracks) = each(%$albums)) {
                if(ref($tracks) eq 'HASH') {
                    while(my $track = each(%$tracks)) {
                        my $path = $self->{path} . '/' . $artist . '/' . $album . '/' . $track;
                        my $tags = $self->{TAG}->getTags($path);
                        my $new_path = $self->{TOMP3}->getNewPath($tags);
                        print $new_path . "\n";
                    }
                }
            }
        }
    }

}


sub isMp3 {
    my $self = shift;
    return shift =~ /\.mp3$/;
}

sub error {
    my $self = shift;
    push @{$self->{errors}}, shift;
}

sub warn {
    my $self = shift;
    push @{$self->{warnings}}, shift;
}

sub msg {
    my $self = shift;
    push @{$self->{msg}}, shift;
}

sub print_log{
    my $self = shift;
    my $log = shift;
    open (MYFILE, '>>' . $self->{log_file});
    print MYFILE $log . "\n\n\n";
    close (MYFILE); 
}

sub DESTROY {
    my $self = shift;
    my $log = '';
    $log .= "Errors: \n";
    foreach my $i (@{$self->{errors}}) {
        $log .=  $i . "\n";
    }   
    $log .=  "\n";
    $log .=  "Warnings: \n"; 
    foreach my $i (@{$self->{warnings}}) {
        $log .=  $i . "\n";
    }  
    $log .=  "\n";
    $log .=  "Messages: \n"; 
    foreach my $i (@{$self->{msg}}) {
        $log .=  $i . "\n";
    }    
    $log .=  "\n";  
    $self->print_log($log);
    print $log;
}
1;


