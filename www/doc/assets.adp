<master src="/packages/hosting-farm/www/doc/responsive-master3">
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<!-- two colms on large, two cols on medium, stacked on small -->
<div class="l-grid-whole m-grid-whole s-grid-whole padded">
  <div class="content-box">

    <div>Welcome @user_name@</div> 
    <div>Resource summary:</div>
    <div style="font-size: small2;">

<if @this_start_row@ nil>
  <if @s@ not nil and @p@ not nil>
    <include src="/packages/hosting-farm/lib/resource-status-summary-1" interval_remaining="@interval_remaining;noquote@" s="@s;noquote@" p="@p;noquote@">
  </if><else>
    <include src="/packages/hosting-farm/lib/resource-status-summary-1" interval_remaining="@interval_remaining;noquote@">
  </else>
</if><else>
  <if @s@ not nil and @p@ not nil>
    <include src="/packages/hosting-farm/lib/resource-status-summary-1" interval_remaining="@interval_remaining;noquote@" s="@s;noquote@" p="@p;noquote@" this_start_row="@this_start_row;noquote@">
  </if><else>
    <include src="/packages/hosting-farm/lib/resource-status-summary-1" interval_remaining="@interval_remaining;noquote@" this_start_row="@this_start_row;noquote@">
  </else>
</else>

        </div>
 </div>
</div>


