#!/usr/bin/perl
#This package has util functions in it for all of perl
#Author: creasetoph

use strict;
use warnings;

package Util;

sub printHash {
    my %hash = %{ shift(@_) };
    my $nest = @_ == 1 ? shift : 0; 
    for my $k (sort keys %hash) {
        my $v = $hash{$k};
        if(ref($v) eq 'HASH') {
            Util::printSpaces($nest);
            print "$k => {\n";
            Util::printHash($v,$nest + 1);
            Util::printSpaces($nest);
            print "}\n";
        }else {
            Util::printSpaces($nest);
            print "$k => $v \n";
        }
    }
}

sub printArray {
    my @arr = @{ shift(@_) };
    my $nest = @_ == 1 ? shift : 0; 
    my $count = 0;
    #$self->printSpaces($nest);
    print "Array [\n";
    for my $i (@arr) {
        if(ref($i) eq 'ARRAY') {
            Util::printSpaces($nest);
            print "[$count] => ";
            Util::printArray($i, $nest + 1);
            Util::printSpaces($nest);
            print "]\n";
        }else {
            Util::printSpaces($nest);
            print "[$count] => " , $i, "\n";
        }
        $count++;
    }
}

sub printSpaces {
    my $num = shift;
    for(my $i = 0;$i < $num;$i++) {
        print "    ";
    }
}

1;
