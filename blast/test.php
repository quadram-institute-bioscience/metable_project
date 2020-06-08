<?php
$pid = isset($_REQUEST['code']) ? $_REQUEST['code'] : '';
?>

<html>
<head>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous" />
<script
  src="https://code.jquery.com/jquery-3.3.1.min.js"
  crossorigin="anonymous"></script>

</head>
<body>
    <div class="container-fluid">
	<h1>View <?php echo $pid; ?></h1>
      <div class="row">
      <div class="col-md-1">
	Input XML<br>
	    <input type="file" id="blastinput" />
      </div>
      <div class="col-md-10"></div>
      <div class="col-md-1"></div>
      </div>
    <div id="blast-multiple-alignments"></div>
    <div id="blast-alignments-table"></div>
    <div id="blast-single-alignment"></div>
    </div>

    <script type="text/javascript" src="node_modules/biojs-vis-blasterjs/lib/html2canvas.js"></script>
    <script type="text/javascript" src="node_modules/biojs-vis-blasterjs/build/blasterjs.js"></script>
    <script type="text/javascript">

    $(document).ready(function(){
        var xmlinput;
        var blasterjs = require("biojs-vis-blasterjs");
	$.post( "xml.php?code=<?php echo $pid; ?>" , function( data ) {
  		xmlinput = data;
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
