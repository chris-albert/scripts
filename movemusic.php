<?php

$music_path = "/media/data/Music/";
$music_path = "/media/data/Downloads/Al Di Meola - Land of the Midnight Sun";
echo "Music Path: ". $music_path . "\n\n";

function getDirStructure($path ,$filter = '') {
        $info = array();
        if(is_dir($path)) {
            if($dh = opendir($path)) {
                while(($file = readdir($dh)) !== false) {
                    if($file != '.' && $file != '..') {
                        $type = filetype($path.$file);
                        if($type === 'dir') {
                            $info[$file] = getDirStructure($path.$file.'/',$filter);
                        }else {
                            if(!empty($filter) && preg_match($filter,$file)) {
                                $info[] = $file;
                            }else if(empty($filter)) {
                                $info[] = $file;
                            }
                        }
                    }
                }
            }
        }else {
            echo "Cant find $path<br />";
        }
        if(!empty($info)) {
            if($type === 'dir') {
                ksort($info);
            }else {
                sort($info);
            }
            return $info;
        }
        return FALSE;
}
$struct = getDirStructure($music_path);

foreach($struct as $v) {
    $path = $music_path . $v;
    print_r(id3_get_tag("$path"));
}

?>
