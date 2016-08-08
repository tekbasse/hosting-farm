
<if @asset_type_id@ not nil>
  <img src="/resources/icons/@asset_type_id@.png" title="@asset_title;noquote@" alt="@asset_title;noquote@">
  <p>@asset_label@ - @asset_description@</p>
  <h2>@title;noquote@</h2>
</if>

<div style="background: url (/resources/icons/@asset_type_id@-background.png); background-size: contain;">
  <if @label@ not nil>
    <h3>@label@</h3>
  </if>
  
<ul>
  @content;noquote@
</ul>  
</div>
