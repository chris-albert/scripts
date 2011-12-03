<?php

class dir2tag {
    public static function getDirStructure($path ,$filter = '') {
        $info = array();
        if(is_dir($path)) {
            if($dh = opendir($path)) {
                while(($file = readdir($dh)) !== false) {
                    if($file != '.' && $file != '..') {
                        $type = filetype($path.$file);
                        if($type === 'dir') {
                            $info[$file] = self::getDirStructure($path.$file.'/',$filter);
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
}
print_r(dir2tag::getDirStructure('/media/data/MusicBackup/'));
?>
