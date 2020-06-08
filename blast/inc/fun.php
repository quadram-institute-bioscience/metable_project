<?php

// has to containg ./p and ./n directories
$db_path = '/var/www/html/blast/db/';

// Populate database  list $database_list 
function databases_html_list($filters) {
    

    // filters is a : delimited set of patterns (eg: 'coli:gnavus')
    $patterns = $filters ? preg_replace('/:/', '|', $filters) : '.';

    $html_databases_list = "<option value='x:x' disabled>~~ Select a Database ~~</option>\n";
    global $db_path;
   
    $db_types = array('n' => 'Nucleotide', 'p' => 'Protein');
    $count = 0;
    foreach ($db_types as $type => $string_type) {
        foreach (array_reverse(glob("$db_path/$type/*.fa")) as $filename) {
            if ( file_exists("$filename.${type}hr")) {

              $basename = basename($filename, '.fa');

              // skip files starting by "_"
              if ( substr($basename, 0, 1) == '_') {
                continue;
              }

              $displayname = ucfirst(
                    preg_replace('/~/', ' - ', 
                        preg_replace('/_/', ' ', $basename)));
              
              if (preg_match("/($patterns)/i", $filename)) {
                $count++;
                $selected = $count==1 ? 'selected' : '';
                $html_databases_list .= "<option class=\"$type-database\"  value=\"$type:$basename\" $selected>" . $displayname . " ($string_type)</option>\n";
              }
              
              
            }
        }
    }
    

    return $html_databases_list;
}

?>