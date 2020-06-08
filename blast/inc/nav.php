<nav class="navbar navbar-expand-lg navbar-dark bg-dark sticky-top">
    <div class="container"> <a class="navbar-brand" href="index.php">
        <i class="fa d-inline fa-flask"></i>
        <b> GMH BLAST</b>
      </a> <button class="navbar-toggler navbar-toggler-right border-0" type="button" data-toggle="collapse" data-target="#navbar11">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbar11">
        <ul class="navbar-nav mr-auto">
          <!--
          <li class="nav-item"> <a class="nav-link" href="quick_search.php">Search</a> </li>
          <li class="nav-item"> <a class="nav-link" href="blast.php">BLAST</a> </li>
          <li class="nav-item"> <a class="nav-link" href="faq.php">FAQs</a> </li>
          -->
        </ul>

        <form id="quick-search" class="form-inline my-2 my-lg-0"  
          action="https://bioinformatics.quadram.ac.uk/confluence/dosearchsite.action" 
          method="get" _lpchecked="1"><fieldset><label for="quick-search-query" class="assistive">
          <input id="quick-search-query" class="form-control mr-sm-2"  type="text" accesskey="q" autocomplete="off" 
            name="queryString"  placeholder="Documentation search">
          <input id="quick-search-submit"  class="btn my-2 my-sm-0 btn-outline-info"  type="submit" value="Search">
          
          </form>

          <!--<button class="btn my-2 my-sm-0 btn-outline-info" type="submit">Search</button> </form>-->
      </div>
    </div>
  </nav>