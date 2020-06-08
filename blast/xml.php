<?php
$dir = '/var/www/html/blast/xml/';
$pid = isset($_REQUEST['code']) ? $_REQUEST['code'] : '';

if (! $argv[0] and strlen($pid) < 3 ) {
  print "<b>ERROR</b>: Missing code";
}
//header('Content-Type: application/xml; charset=utf-8');
$xml_file = $argv[0] ? $dir . 'test.xml' : $dir . $pid . '.xml';

if (file_exists($xml_file) ) {
  if(filesize($xml_file)) {
    readfile($xml_file);
  } else {
    print "<b>ERROR:</b>: $pid blast not found";
  }
  
} else {
  print "<b>ERROR</b>: $pid not found";
}
?>

