#!/usr/local/bin/perl

$path = $ARGV[0];
print "Looking into " . $path . "\n";
opendir(DIR, $path) || die "Cant open dir: $!";
while(my $file = readdir(DIR)) {
    if(-d "$path$file") {
        print "$path$file is a directory\n";  
    }else {
	print $file . "\n";
	($filename,$ext) = split(/\./,$file);
	print "filename : " . $filename . "\n";
        print "extension: " . $ext . "\n";
    }
    print "\n";
}
closedir(DIR);
