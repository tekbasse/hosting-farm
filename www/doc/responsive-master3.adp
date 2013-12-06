<!DOCTYPE html>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->

<html<if @doc.lang@ not nil> lang="@doc.lang;noquote@"</if>>

<head>
    <title<if @doc.title_lang@ not nil and @doc.title_lang@ ne @doc.lang@> lang="@doc.title_lang;noquote@"</if>>@doc.title;noquote@</title>
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <meta name="viewport" content="width=device-width">
<!--
<multiple name="meta">    <meta<if @meta.http_equiv@ not nil> http-equiv="@meta.http_equiv;noquote@"</if><if @meta.name@ not nil> name="@meta.name;noquote@"</if><if @meta.scheme@ not nil> scheme="@meta.scheme;noquote@"</if><if @meta.lang@ not nil and @meta.lang@ ne @doc.lang@> lang="@meta.lang;noquote@"</if> content="@meta.content@">
</multiple>
<multiple name="link">    <link rel="@link.rel;noquote@" href="@link.href;noquote@"<if @link.lang@ not nil and @link.lang@ ne @doc.lang@> lang="@link.lang;noquote@"</if><if @link.title@ not nil> title="@link.title;noquote@"</if><if @link.type@ not nil> type="@link.type;noquote@"</if><if @link.media@ not nil> media="@link.media@"</if>>
</multiple>
-->
  <link href="/resources/extra-strength-responsive-grids-master/css/grid.css" rel="stylesheet" />
  <link href="/resources/extra-strength-responsive-grids-master/css/main.css" rel="stylesheet" />
<!--
<multiple name="___style"> <style type="@___style.type;noquote@" <if @___style.lang@ not nil and @___style.lang@ ne @doc.lang@> lang="@___style.lang;noquote@"</if><if @___style.title@ not nil> title="@___style.title;noquote@"</if><if @___style.media@ not nil> media="@___style.media@"</if>>@___style.style;noquote@
</style>
</multiple>
-->
<script type="text/css">
table tr td {
border: 1px solid #ccc; 
vertical-align: top;
text-align: right;

}
table tr td .ctr {
border: 1px solid #ccc; 
vertical-align: top;
text-align: center;

}
</script>

<multiple name="headscript">   <script type="@headscript.type;noquote@"<if @headscript.src@ not nil> src="@headscript.src;noquote@"</if><if @headscript.charset@ not nil> charset="@headscript.charset;noquote@"</if><if @headscript.defer@ not nil> defer="@headscript.defer;noquote@"</if>><if @headscript.content@ not nil>@headscript.content;noquote@</if></script>

</multiple>
<if @head@ not nil>@head;noquote@</if>
  <!--[if lt IE 9]>
      <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
      <script>window.html5 || document.write('<script src="js/vendor/html5shiv.js"><\/script>')</script>
      <script src="js/vendor/respond.min.js"></script>
  <![endif]-->
</head>
<body<if @body.class@ not nil> class="@body.class;noquote@"</if><if @body.id@ not nil> id="@body.id;noquote@"</if><if @event_handlers@ not nil>@event_handlers;noquote@</if>>

  @header;noquote@

<div class="page-wrap">

  <section id="main" role="main">
    
    <div class="grid-whole padded">
<!-- header -->
    </div>


        
    <if @user_messages:rowcount@ gt 0>
      <div class="grid-whole">
        <div class="grid-whole m-grid-whole s-grid-whole padded">
          <div class="content-box">
              <div id="alert-message">
                <multiple name="user_messages">
                  <div class="alert">
                    <strong>@user_messages.message;noquote@</strong>
                  </div>
                </multiple>
              </div>
          </div>
        </div>
      </div>
    </if>
    
    <div class="grid-whole equalize"><!-- 3 -->

<slave>

    </div><!-- 3 -->

  </section><!-- /#main -->
</div><!-- /.page-wrap -->

  @footer;noquote@
<multiple name="body_script">    <script type="@body_script.type;noquote@"<if @body_script.src@ not nil> src="@body_script.src;noquote@"</if><if @body_script.charset@ not nil> charset="@body_script.charset;noquote@"</if><if @body_script.defer@ not nil> defer="@body_script.defer;noquote@"</if>><if @body_script.content@ not nil>@body_script.content;noquote@</if></script>
</multiple>

<!--
<img id="resize" src="/resources/extra-strength-responsive-grids-master/img/resize.png" alt="">
-->


<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
<script>window.jQuery || document.write('<script src="/resources/extra-strength-responsive-grids-master/js/vendor/jquery-1.8.3.min.js"><\/script>')</script>
<script src="/resources/extra-strength-responsive-grids-master/js/vendor/equalize.min.js"></script>
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
