<master src="/www/responsive-master3">
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<!-- four colms on large, two cols on medium, stacked on small -->
<div class="grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">

    <div>Account Management System</div>
    <div>Welcome @user_name@</div>
    <div>Resource summary:<br>
    <include src="/packages/hosting-farm/lib/time-interval-remaining" time1="@t1;noquote@" time2="@t2;noquote@">
</div>
      <div>Summary for @current_dt@</div>
      <table style="border: 1px solid #ccc; font-size: small; width: 100%; padding-left: 0; padding-right: 0; margin-left: 0; margin-right: 0;">
  <tr><td>Asset Type</td><td>Quota</td><td>Current sample</td><td>Projected end of interval</td></tr>
  <tr><td>contract</td><td>per asset</td><td>day 27.96</td><td>day 30</td></tr>
  <tr><td>HW Traffic</td><td>1024 TB</td><td>136.69 GB</td><td>146.67 GB</td></tr>
  <tr><td>HW Storage</td><td>10.00 TB</td><td>2.37 TB</td><td>3.25 TB</td></tr>
  <tr><td>HW Memory</td><td>768.00 GB</td><td>537.00 GB</td><td> 580.00 GB</td></tr>
  <tr><td>VM Traffic</td><td>1024 GB</td><td>136.69 MB</td><td>146.67 MB</td></tr>
  <tr><td>VM Storage</td><td>10.00 GB</td><td>2.37 GB</td><td>3.25 GB</td></tr>
  <tr><td>VM Memory</td><td>768.00 MB</td><td>537.00 MB</td><td> 580.00 MB</td></tr>
  <tr><td>SS Traffic</td><td>1024 MB</td><td>136.69 KB</td><td>146.67 KB</td></tr>
  <tr><td>SS Storage</td><td>10.00 MB</td><td>2.37 MB</td><td>3.25 MB</td></tr>
  <tr><td>SS Memory</td><td>768.00 KB</td><td>537.00 KB</td><td> 580.00 KB</td></tr>
</table>  
      <div>
        Projected renewal date/time:
        Current date/time:
      </div>

  </div>
</div>
<div class="grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">

    <ul>
      @menu_1_html;noquote@
    </ul>

  </div>
</div>
<div class="grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">
 
    <ul>
      @menu_2_html;noquote@
    </ul>

  </div>
</div>
<div class="grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">

    <ul>
      @menu_3_html;noquote@
    </ul>

  </div>
</div>
