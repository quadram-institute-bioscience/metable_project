<html>
<head>
<?php
require('inc/head.php');
  $messages    = '';
  $job_id      = uniqid();
  $query       = $_REQUEST['sequence'];
  $blast_type  = $_REQUEST['blast_type'];
  $evalue      = $_REQUEST['evalue'];
  $db_string   = $_REQUEST['database'];

 
  if ( ! isset($blast_type) ) {
    $messages .= '<li>BLAST settings error: BLAST type unknown: (' . $blast_type . ')';
  }
  if (! isset($evalue)) {
    $messages .= '<li>BLAST settings error: evalue unknown: ' . $evalue; 
  }

  if ( $query == '') {
    $messages .= '<li>Empty sequence (query)</li>'; 
  }
  
  $db_ar = explode(':', $db_string);
  $db_file  = dirname(__FILE__) . '/db/' . $db_ar[0] . '/' . $db_ar[1] .'.fa';

  if ($db_ar[0] == 'p') {
    //protein database
    if ($blast_type !== 'blastp' and $blast_type !== 'blastx') {
      $messages .= "<li>Wrong database: protein ($db_ar[1]) database not compatible with $blast_type</li>";
    }
  } elseif ($db_ar[0] == 'n') {
    // nucleotide database
    if ($blast_type !== 'blastn' and $blast_type !== 'tblastn') {
      $messages .= "<li>Wrong database: nucleotide database ($db_ar[1]) not compatible with $blast_type</li>";
    }
  } else {
    $messages .= "<li>Wrong database: '$db_ar[0]' $db_string bad format (selection menu was probably malformed)</li>";
  }
  // check compatibility of algorithm and database  
  $command = $blast_type . ' -outfmt 5 -db ' . $db_file . ' -evalue ' . $evalue;
?>
</head>
<body>


<?php require('inc/nav.php'); ?>

  <div class="py-3 text-center">
    <div class="container">
      <div class="row">
        <div class="col-md-12 text-center">
          <h1>Preparing to BLAST</h1>
          <p>JOB ID:<?= $job_id ? $job_id : 'Not_Received' ?></p>
        </div>
      </div>

  </div>
  <div class="py-5">
    <div class="container">
      <div class="row">
        <div class="col-md-12 text-left">

<?php

  if ($messages) {
      // print errors
      print "\n\t<h2>Bad parameters</h2>\n\t";
      print '<ul>' . $messages . "\n</ul>\n";
  } else {
    $query_file  = dirname(__FILE__) . '/input/' . $job_id . '.fa';
    $output_file = dirname(__FILE__) . '/xml/'   . $job_id . '.xml';
    if (!file_put_contents($query_file, $query)) {
        print "<h4>Error</h4>\nError writing to $query_file";
    } else {
        
        
        $command .= ' -query ' . $query_file . ' -out ' . $output_file;
        print "<h3>Preparing output...</h3>\n";

        if (file_exists("$output_file.log")) {
          // do not blast twice the same thing
        } else {
          exec(sprintf("%s > %s 2>&1 & echo $!", $command, "$output_file.log"), $pidArr);
        }
         
         $results_url = "http://" . $_SERVER['SERVER_NAME'] . dirname( $_SERVER['REQUEST_URI']) . 
          '/view_blast.php?code=' . $job_id;
         
         if ($pidArr[0]) {
           
            $results_url .= '&check=' . $pidArr[0];
         } 
         print "\n<script type=\"text/javascript\">
          window.location.replace(\"$results_url\");
         </script>\n";
    }
  }
 

?>


        </div>
      </div>
    </div>
  </div>

</html>