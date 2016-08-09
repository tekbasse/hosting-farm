
<if @asset_type_id@ not nil>
  <img src="resources/icons/@asset_type_id@.png" title="@asset_title;noquote@" alt="@asset_title;noquote@">
  <if @asset_label@ not nil>
    <p>@asset_label@ - @asset_description@</p>
    <h2>@asset_title;noquote@</h2>
  </if>
</if>

<div style="background-color: transparent; background-repeat: no-repeat; background-image: url(resources/icons/@asset_type_id@-background.png); background-size: 100% 100% ;">

  <div style="margin: .5in; padding: .5in">
    <if @label@ not nil>
      <h3>@label@</h3>
    </if>
    
    <ul>
      @content;noquote@
    </ul>  
  </div>
</div>
