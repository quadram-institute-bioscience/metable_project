
<!DOCTYPE html>
<html>

<head>
<?php
 $patterns = isset($_REQUEST['db']) ? $_REQUEST['db'] : '';
 $pid = isset($_REQUEST['code']) ? $_REQUEST['code'] : '';
 require('inc/head.php');
 require('inc/fun.php');

?>
 
</head>

<body>


<?php require('inc/nav.php'); ?>

  <div class="py-3 text-center">
    <div class="container">
      <div class="row">
        <div class="col-md-12 text-center">
          <h1>GMH Blast</h1>
        </div>
      </div>

  </div>
  <div class="py-5">
    <div class="container">
      <div class="row">
        <div class="col-md-12 text-left">

<form action="blast.php" method="post">
<input type="hidden" name="blast_id" value="<?= printf("%s", uniqid('', true)); ?>">

<fieldset>
      <label>BLAST Type</label>
      <div class="form-check n-algo">
        <label class="form-check-label">
          <input type="radio" class="form-check-input" name="blast_type" id="blastn" value="blastn" checked="true">
          <strong>BLASTn</strong> - Nucleotide query against a nucleotide db</label>
      </div>
      <div class="form-check p-algo">
        <label class="form-check-label">
          <input type="radio" class="form-check-input" name="blast_type" id="blastp" value="blastp" >
          <strong>BLASTp</strong> - Protein query against a protein db</label>
      </div>
      <div class="form-check p-algo">
        <label class="form-check-label">
          <input type="radio" class="form-check-input" name="blast_type" id="blastx" value="blastx" >
          <strong>BLASTx</strong> - Nucleotide query (translated) against a protein db</label>
      </div>
      <div class="form-check n-algo">
        <label class="form-check-label">
          <input type="radio" class="form-check-input" name="blast_type" id="tblastn" value="tblastn" >
          <strong>tBLASTn</strong> - Protein query against a nucleotide db (translated)</label>
      </div>
  </fieldset>

    
  <fieldset>
    <div class="form-group">
      <label for="database">Database</label>
      <select class="form-control" id="database" name="database">
	    <?= databases_html_list($patterns) ?>
      </select>
    </div>
    <div class="form-group">
      <label for="sequence">Sequences in FASTA format</label>
      <textarea name="sequence" class="form-control" id="sequence" rows="8" spellcheck="false"></textarea>
    </div>
    </fieldset>

    <fieldset>
    <div class="form-group">
      <label for="evalue">E-value</label>
      <select class="form-control" id="evalue" name="evalue">
	      <option value="1e-21">1e-21</option>
        <option value="1e-18">1e-18</option>
        <option value="1e-15">1e-15</option>
        <option value="1e-12">1e-12</option>
        <option value="1e-9">1e-9</option>
      </select>
    </div>
    </fieldset>
    <button type="submit" class="btn btn-primary">BLAST</button>

</form>


        </div>
      </div>
    </div>
  </div>


<?php require('inc/footer.php'); ?>

    <script type="text/javascript" src="node_modules/biojs-vis-blasterjs/lib/html2canvas.js"></script>
    <script type="text/javascript" src="node_modules/biojs-vis-blasterjs/build/blasterjs.js"></script>
    <script type="text/javascript">
        $(document).ready(function(){
            $(".n-algo").click(function(){
              $("#database").val('x:x');
              $(".p-database").hide();
              $(".n-database").show();
            });
            $(".p-algo").click(function(){
              $("#database").val('x:x');
              $(".n-database").hide();
              $(".p-database").show();
            });
          });
    </script>

</body>

</html>

