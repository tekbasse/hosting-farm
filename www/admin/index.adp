<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<h1>Administration</h1>
<h2>System status</h2>
<ul><li>
number of active assets:
</li><li>
number of users with active assets:
</li><li>
number of active customers
</li></ul>
<h3>Procs in stack</h3>




<ul><li>
    <a href="../doc/index">Documentation</a>
</li><li>
    <a href="privilege-map">Privileges map</a>
</li><li>
    <a href="doc-map">example site map</a> of a deployed package in context of other packages.
</li></ul>
<p>This is a good place to report system summary status etc.</p>
<pre>
 @contents;noquote@
</pre>
<if @offer_demo_p;noquote@ true>
  <p>If you have installed this package as part of a temporary system
    and want to populate it with some demo data, 
    browse to the <a href="demo-install">demo-install</a> page.
    When the page has finished loading, data will be 
    generated. Proceed to another page.
  </p>
</if>
