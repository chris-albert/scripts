#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

my $path = shift || '';
my $start = shift || 0;
print $path ,"\n";

opendir(IMD,$path) or die ("Dir $path doesnt exits!");
my @dirs = readdir(IMD);
@dirs = sort(@dirs);
my %hash = ();
my $i = $start;
foreach my $dir (@dirs) {
    unless($dir eq '.' || $dir eq '..') {
        if(-d "$path/$dir") {
            print "Not renaming $path/$dir\n";
            #TODO Handle nested
        }else{
            my $file = "$path/$dir";
            $file =~ /.*\.(.*)$/;
            print "Renaming: \n";
            print $file . "\n";
            my $ext = $1 || 'flv';
            my $nf = File::Basename::dirname($file) .'/' . $i . '.' . lc $ext;
            print "To: \n";
            print $nf . "\n";
            $i++;
            rename($file,$nf) or print"Failed! \n\n";

        }
    }
}
