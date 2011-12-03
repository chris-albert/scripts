<?php

class mediamover {

    //no traling slash
    public static $path = "/media/data/Music";
#    public static $path = "/home/creasetoph/Music";
    public static $move_path = "/media/sd";

    public static $filename = "/media/data/scripts/mediamover/phone.txt";

    public static $live = true;
    
    public static function getFolderSize($folder) {
        $size = 0;
        if ($handle = opendir($folder)) {
            while (false !== ($file = readdir($handle))) {
                if ($file != "." && $file != "..") {
                    $path = $folder . '/' . $file;
                    if(is_dir($path)) {
                        $size += self::getFolderSize($path);
                    }else {
                        $size += filesize($path);
                    }
                }
            }
            closedir($handle);
        }
        return $size;
    }

    public static function parseFile() {
        $files = array();
        $counter = 0;
        $file_arr = file(self::$filename);
        for($i = 0,$l = count($file_arr); $i < $l;$i++) {
            $line = trim($file_arr[$i]);
            if($line === '*') {
                $files[trim($file_arr[$i - 1])] = self::getArtistAlbums(self::$path . '/' . trim($file_arr[$i - 1]));
            }else if($line && $line[0] === '~'){
                $counter++;
                $files[trim($file_arr[$i - $counter])][] = substr($line,1);
            }else {
                //we hit a artist, reset shit
                $counter = 0;
            }
        }
        return $files;
    }

    public static function buildPaths($files) {
        $paths = array();
        foreach($files as $artist => $albums) {
            foreach($albums as $album) {
                $paths[] = implode('/',array(self::$path,$artist,$album));
            }
        }
        return $paths;
    }

    public static function getPathsSize($paths) {
        $size = 0;
        foreach($paths as $path) {
            $size += self::getFolderSize($path);
        }
        return $size;
    }

    public static function prettyPrint($files) {
        foreach($files as $artist => $albums) {
            echo "\n" . $artist . "\n";
            echo self::getDashes(strlen($artist)) . "\n";
            foreach($albums as $album) {
                echo '   ' .  $album . "\n";
            }
        }
    }

    public static function formatPrint($files) {
        foreach($files as $artist => $albums) {
            echo "\n" . $artist . "\n";
            foreach($albums as $album) {
                echo '~' .  $album . "\n";
            }
        }
    }

    public static function printSize($size) {
        echo "Size in Bytes : " . $size . "\n";
        echo "Size in MBytes: " . round(($size / 1000000),2) . "\n";
        echo "Size in GBytes: " . round(($size / 1000000000),2) . "\n";
    }

    public static function getDashes($num) {
        $dashes = '';
        for($i = 0; $i < $num;$i++) {
            $dashes .= '-';
        }
        return $dashes;
    }

    public static function getArtistAlbums($artist_path) {
        $paths = array();
        if ($handle = opendir($artist_path)) {
            while (false !== ($file = readdir($handle))) {
                if ($file != "." && $file != "..") {
                    $path = $artist_path . '/' . $file;
                    if(is_dir($path)) {
                        $paths[] = $file;
                    }
                }
            }
            closedir($handle);
        }
        return $paths;
    }

    public static function getDirContents($dir) {
        $contents = array();
        if ($handle = opendir($dir)) {
            while (false !== ($file = readdir($handle))) {
                if ($file != "." && $file != "..") {
                    $contents[] = implode('/',array($dir,$file));
                }
            }
            closedir($handle);
        }
        return $contents;
    }

    public static function movePaths($paths) {
        if(!is_dir(self::$move_path)) {
            if(self::$live) {
                mkdir(self::$move_path,0777,true);
            }
        }
        foreach($paths as $path) {
            $files = self::getDirContents($path);
            foreach($files as $file) {
                $tmp = explode('/',$file);
                $count = count($tmp);
                $path_arr = array(self::$move_path,$tmp[$count - 3],$tmp[$count - 2],$tmp[$count - 1]);
                $to = implode('/' , $path_arr);
                array_pop($path_arr);
                $dir_path = implode('/',$path_arr);
                if(!is_dir($dir_path)) {
                    if(self::$live) {
                        mkdir($dir_path,0777,true);
                    }
                }
                echo "Copying files...\n";
                echo 'From: ' . $file . "\n";
                echo 'To  : ' . $to ."\n\n";
                if(self::$live) {
                    copy($file,$to);
                }
            }
        }
    }
}

#echo mediamover::getFolderSize(mediamover::$path) ."\n\n";
$files = mediamover::parseFile();
$paths = mediamover::buildPaths($files);
mediamover::prettyPrint($files);
#mediamover::formatPrint($files);

$size = mediamover::getPathsSize($paths);
echo "\n\n";
mediamover::printSize($size);
mediamover::movePaths($paths);
echo "\n\n\n";
?>
