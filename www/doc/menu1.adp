<master src="/packages/hosting-farm/www/doc/responsive-master3">
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<!-- four colms on large, two cols on medium, stacked on small -->
<div class="l-grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">

    <div class="small">Account Management System</div>
    <div>Welcome @user_name@</div> 
    <div>Resource summary:<br>
      <include src="/packages/hosting-farm/lib/time-interval-remaining" time1="@t1;noquote@" time2="@t2;noquote@"> 
    </div> 
    
  </div>
</div>

<div class="l-grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">

<div>&nbsp;</div>

      @menu_1_html;noquote@

<div>&nbsp;</div>

  </div>
</div>

<div class="l-grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">
 
<div>&nbsp;</div>

      @menu_2_html;noquote@

<div>&nbsp;</div>

  </div>
</div>
<div class="l-grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">

<div>&nbsp;</div>

      @menu_3_html;noquote@

<div>&nbsp;</div>

  </div>
</div>
