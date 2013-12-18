<master src="/packages/hosting-farm/www/doc/responsive-master3">
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<!-- two colms on large, two cols on medium, stacked on small -->
<div class="l-grid-whole m-grid-whole s-grid-whole padded">
  <div class="content-box">

    <div>Welcome @user_name@</div> 
    <div>Resource summary:</div>
    <div style="font-size: small2;">
<include src="/packages/hosting-farm/lib/resource-status-summary-1" interval_remaining="@interval_remaining;noquote@" columns="2">
        </div>
 </div>
</div>


