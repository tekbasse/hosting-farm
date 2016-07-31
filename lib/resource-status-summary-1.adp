<!-- grid base is 12, so grid-2 is one sixth -->
<div class="l-grid-2 m-grid-whole s-grid-whole">
  <div class="content-box padded">
    <div>&nbsp;</div>

<if @prev_bar@ not nil or @next_bar@ not nil>
  <p>Jump to: @prev_bar;noquote@ &nbsp; (@current_bar;noquote@) &nbsp; @next_bar;noquote@</p>
</if>

@nav_html;noquote@
<div>&nbsp;</div>
  </div>
</div>

<div class="l-grid-10 m-grid-whole s-grid-whole">
  <div class="content-box padded">
    <div>&nbsp;</div>
    @page_html;noquote@
    <div>&nbsp;</div>
  </div>
</div>
