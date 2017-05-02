@doc.type;literal@
<html<if @doc.lang@ not nil> lang="@doc.lang;literal@"</if>>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->
<head>
    <title<if @doc.title_lang@ not nil and @doc.title_lang;literal@ ne @doc.lang;literal@> lang="@doc.title_lang;literal@"</if>>@doc.title@</title>
<!--   <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"> -->
  <meta name="viewport" content="width=device-width">
<multiple name="meta">    <meta<if @meta.http_equiv@ not nil> http-equiv="@meta.http_equiv;literal@"</if><if @meta.name@ not nil> name="@meta.name;noquote@"</if><if @meta.scheme@ not nil> scheme="@meta.scheme;noquote@"</if><if @meta.lang@ not nil and @meta.lang;literal@ ne @doc.lang;literal@> lang="@meta.lang;literal@"</if> content="@meta.content@">
</multiple>
<multiple name="link">    <link rel="@link.rel;literal@" href="@link.href@"<if @link.lang@ not nil and @link.lang;literal@ ne @doc.lang;literal@> lang="@link.lang;literal@"</if><if @link.title@ not nil> title="@link.title@"</if><if @link.type@ not nil> type="@link.type;literal@"</if><if @link.media@ not nil> media="@link.media;literal@"</if>>
</multiple>

<link href="/resources/hosting-farm/hf.css" rel="stylesheet" />
<!--  Above is a combination of following with latest normal.css
  <link href="/resources/extra-strength-responsive-grids-master/css/grid.css" rel="stylesheet" />
  <link href="/resources/extra-strength-responsive-grids-master/css/main.css" rel="stylesheet" />
-->

<multiple name="___style"> <style type="@___style.type;literal@" <if @___style.lang@ not nil and @___style.lang;literal@ ne @doc.lang;literal@> lang="@___style.lang;literal@"</if><if @___style.title@ not nil> title="@___style.title@"</if><if @___style.media@ not nil> media="@___style.media;literal@"</if>>@___style.style;literal@
</style>
</multiple>

<comment>
   These two variables have to be set before the XinhaCore.js is loaded. To 
  enforce the order, it is put here.
</comment>
<if @::acs_blank_master__htmlareas@ defined and @::xinha_dir@ defined and @::xinha_lang@ defined>
<script type="text/javascript">
_editor_url = "@::xinha_dir;literal@"; 
_editor_lang = "@::xinha_lang;literal@";
</script>
</if>

<multiple name="headscript">   <script type="@headscript.type;literal@"<if @headscript.src@ not nil> src="@headscript.src;literal@"</if><if @headscript.charset@ not nil> charset="@headscript.charset;literal@"</if><if @headscript.defer@ not nil> defer="@headscript.defer;literal@"</if><if @headscript.async@ not nil> async="@headscript.async;literal@"</if>><if @headscript.content@ not nil>@headscript.content;noquote@</if></script>
</multiple>

<if @head@ not nil>@head;literal@</if>
  <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <script>window.html5 || document.write('<script src="js/vendor/html5shiv.js"><\/script>')</script>
      <script src="js/vendor/respond.min.js"></script>
  <![endif]-->
</head>
<body<if @body.class@ not nil> class="@body.class;literal@"</if><if @body.id@ not nil> id="@body.id;literal@"</if><if @event_handlers@ not nil>@event_handlers;literal@</if>>
  @header;literal@
<slave>
  @footer;literal@
<multiple name="body_script">    <script type="@body_script.type;literal@"<if @body_script.src@ not nil> src="@body_script.src;literal@"</if><if @body_script.charset@ not nil> charset="@body_script.charset;literal@"</if><if @body_script.defer@ not nil> defer="@body_script.defer;literal@"</if><if @body_script.async@ not nil> async="@body_script.async;literal@"</if>><if @body_script.content@ not nil>@body_script.content;literal@</if></script>
</multiple>

</body>
</html>




<div class="page-wrap">
  <section id="main" role="main">
    
    <div class="grid-whole padded">
<!-- header -->
    </div>
        
    <if @user_messages:rowcount@ gt 0>
      <div class="grid-whole">
        <div class="l-grid-whole m-grid-whole s-grid-whole padded-sides">
          <div class="content-box padded-sides">
              <div id="alert-message">
                <multiple name="user_messages">
                  <div class="alert">
                    <strong>@user_messages.message;literal@</strong>
                  </div> 
                </multiple>
              </div>
          </div>
        </div>
      </div>
    </if>
    
    <div class="grid-whole"><!-- 3 -->

<slave>

    </div><!-- 3 -->

  </section><!-- /#main -->
</div><!-- /.page-wrap -->

  @footer;literal@
<multiple name="body_script">    <script type="@body_script.type;literal@"<if @body_script.src@ not nil> src="@body_script.src;literal@"</if><if @body_script.charset@ not nil> charset="@body_script.charset;literal@"</if><if @body_script.defer@ not nil> defer="@body_script.defer;literal@"</if>><if @body_script.content@ not nil>@body_script.content;literal@</if></script>
</multiple>

<!--
<img id="resize" src="/resources/extra-strength-responsive-grids-master/img/resize.png" alt="">
-->
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
<script>window.jQuery || document.write('<script src="/resources/hosting-farm/esrg/jquery-1.8.3.min.js"><\/script>')</script>
<script src="/resources/hosting-farm/esrg/equalize.min.js"></script>
<script>
  // smart resize - http://paulirish.com/2009/throttled-smartresize-jquery-event-handler/
  (function($,sr){
 
    // debouncing function from John Hann
    // http://unscriptable.com/index.php/2009/03/20/debouncing-javascript-methods/
    var debounce = function (func, threshold, execAsap) {
        var timeout;
   
        return function debounced () {
            var obj = this, args = arguments;
            function delayed () {
                if (!execAsap)
                    func.apply(obj, args);
                timeout = null; 
            };
   
            if (timeout)
                clearTimeout(timeout);
            else if (execAsap)
                func.apply(obj, args);
   
            timeout = setTimeout(delayed, threshold || 100); 
        };
    }
    // smartresize 
    jQuery.fn[sr] = function(fn){  return fn ? this.bind('resize', debounce(fn)) : this.trigger(sr); };
   
  })(jQuery,'smartresize');

  $(function() {
    // use equalize to equalize the heights of content elements
    $('.equalize').equalize({children:'.content-box'});

    // re-equalize on resize
    $(window).smartresize(function(){  
      $('.equalize').equalize({reset:true, children:'.content-box'});
    });

  });
</script>

</body>
</html>
