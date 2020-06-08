<?php
$pid = isset($_REQUEST['code']) ? $_REQUEST['code'] : '';
$jobid = isset($_REQUEST['check']) ? $_REQUEST['check'] : '';


?>
<!DOCTYPE html>
<html>

<head>
<?php
 include('inc/head.php');
?>
</head>

<body>


<?php include('inc/nav.php'); ?>

  <div class="py-3 text-center">
    <div class="container">
      <div class="row">
        <div class="col-md-12 text-center">
          <h1>GMH Blast</h1>
          <p>Results page for <strong>JOB:<?= $pid ?></strong></p>
          <?php
          $results = 0;
          if (! file_exists('xml/' . $pid . '.xml')) {
            print "BLAST results not ready. Refreshing in 3 seconds.";
            print '
            <script type="text/javascript">
            setTimeout(function(){
              window.location.reload(1);
           }, 3000);
           </script>';
          } elseif (! filesize('xml/' . $pid . '.xml')) {
            print "Still working...";
            print '
            <script type="text/javascript">
            setTimeout(function(){
              window.location.reload(1);
           }, 5000);
           </script>';
          } else {
            $results = 1;
          }
        ?>
	       <div id="blast-multiple-alignments"></div>
    		 <div id="blast-alignments-table"></div>
	       <div id="blast-single-alignment"></div>

        </div>
      </div>

  </div>
  <div class="py-5">
    <div class="container">
      <div class="row">
        <div class="col-md-12">

    	  	</div>
        </div>
      </div>
    </div>
  </div>



    <script type="text/javascript" src="node_modules/biojs-vis-blasterjs/lib/html2canvas.js"></script>
    <script type="text/javascript" src="node_modules/biojs-vis-blasterjs/build/blasterjs.js"></script>
    <script type="text/javascript">
    $(document).ready(function(){
        var xmlinput;
        var blasterjs = require("biojs-vis-blasterjs");
        $.post( "xml.php?code=<?php echo $pid; ?>" , function( data ) {
                xmlinput = <?php echo $results ?  'data' : '<xml></xml>' ; ?>;
                var instance  = new blasterjs({
                string: xmlinput,
                multipleAlignments: "blast-multiple-alignments",
                    alignmentsTable: "blast-alignments-table",
                    singleAlignment: "blast-single-alignment"
                });

        });
    });
    </script>

</body>

</html>

