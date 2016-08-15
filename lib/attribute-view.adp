
<if @sub_type_id@ not nil>
  <img src="resources/icons/@sub_type_id@.png" title="@sub_asset_title;noquote@" alt="@sub_asset_title;noquote@">
  <if @sub_asset_label@ not nil>
    <p>@sub_asset_label@ - @sub_asset_description@</p>
    <h2>@sub_asset_title;noquote@</h2>
  </if>
</if>

<div style="background-color: transparent; background-repeat: no-repeat; background-image: url(resources/icons/@sub_type_id@-background.png); background-size: 100% 100% ; padding: 0 ; margin: 0;">
  <div style="padding-top: 10%; margin-top: 10%;padding-bottom: 10%; margin-bottom: 10%;">
  <div style="padding: 10%; margin: 10%;">
    <if @sub_label@ not nil>
      <h3>@sub_label@</h3>
    </if>
    
    <ul>
      @content;noquote@
    </ul>  
  </div>
</div>
</div>
