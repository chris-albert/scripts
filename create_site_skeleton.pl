#!/usr/bin/perl
# This script is used to copy site skeleton from a certain directory
use strict;
use warnings;
use Util;
use File::Path;
use File::Copy;
use File::Basename;

my $from_path = shift || '';
my $to_path = shift || '';

my %site_paths = (
    application => {
        controller => {
            'BaseController.class.php' => '',
            'FrontController.class.php' => ''
        },
        model => {
            'BaseModel.class.php' => ''
        },
        objects => {
            'MySql.class.php' => '',
            'Pagination.class.php' => '',
            'User.class.php' => ''
        },
        view => {
            'Template.class.php' => '',
            templates => {}
        },
        'Registry.class.php' => '',
        'Util.class.php' => ''
    },
    config => {
        'config.ini' => ''
    },
    logs => {},
    tmp => {},
    www => {
        css => {},
        flash => {},
        images => {},
        js => {
            'sizzle.js' => '',
            'creasetoph_env.js' => '',
            'creasetoph_base.js' => '',
            'creasetoph_dialog.js' => ''
        },
        'index.php' => '',
        '.htaccess' => ''
    }
);
my $path_arr = getPathList(\%site_paths);
#Util::printArray($path_arr);
my @dir_arr = [];
my @file_arr = [];
foreach my $i (@$path_arr) {
    my $loc_path = "$from_path$i";
    my $loc_to_path = "$to_path$i";
    my $from_base_path = File::Basename::dirname $loc_path;
    my $to_base_path = File::Basename::dirname $loc_to_path;
    if(-d $loc_path) {
        unless(-d $loc_to_path) {
            print "creating $loc_to_path\n";
            File::Path::mkpath($loc_to_path);
        }
    }elsif(-f $loc_path) {
        unless(-d $to_base_path) {
            print "creating $to_base_path\n";
            File::Path::mkpath($to_base_path);
        }
        print "copying $loc_path to  $loc_to_path\n";
        File::Copy::copy($loc_path,$loc_to_path);
    }
}




sub getPathList {
    my $arr = shift;
    my $str2 = recursiveLoop('',$arr);
    sub recursiveLoop {
        my $str = shift;
        my %arr2 = %{ shift(@_) };
        my $final = '';
        if(%arr2) {
            while (my ($k,$v) = each(%arr2)) {
                if(ref($v) eq 'HASH') {
                    $final .= recursiveLoop("$str/$k",$v);
                }else {
                    $final .= "$str/$k\n"
                }
            }
        }else {
            $final = $str ."\n";
        }
        return $final;
    }
    my @ret = split('\n',$str2);
    return \@ret;
}



