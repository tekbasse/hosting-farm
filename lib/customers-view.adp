<!-- grid base is 12, so grid-2 is one sixth -->
<div class="l-grid-2 m-grid-whole s-grid-whole">
</div>

<div class="l-grid-10 m-grid-whole s-grid-whole">
  <div class="content-box padded">
    <if @prev_bar@ not nil>
     @prev_bar;noquote@ 
     @current_bar;noquote@
    </if>
  </div>
  <div class="content-box padded">
    <div class="content-box padded">
    @page_html;noquote@
    </div>
  </div>
  <div class="content-box padded">
    <if @next_bar@ not nil>
      @next_bar;noquote@
    </if>
  </div>

</div>


