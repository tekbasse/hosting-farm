<!-- master src="/packages/hosting-farm/www/doc/responsive-master3" -->
<!--master src="/www/blank-master" -->
<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<!-- four colms on large, two cols on medium, stacked on small -->
<div class="l-grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box padded-sides">

    <h5>Account Management System</h5>
<if @user_name@ not nil>
    <div>Welcome, @user_name@</div> 
</if>
<h5>Renewal Countdown</h5>
    <include src="/packages/hosting-farm/lib/time-interval-remaining" time1="@t1;noquote@" time2="@t2;noquote@"> 
<h5>Summary <br>Resource, Usage, Status:</h5>
    <include src="/packages/hosting-farm/lib/resource-status-summary-2" interval_remaining="@interval_remaining;noquote@" list_limit="3"> 
    <div> &nbsp; </div>
    
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
