
<if @has_icon_p@ true>
  <img src="@icon_url@" title="@asset_title;noquote@" alt="@asset_title;noquote@">
  <if @asset_label@ not nil>
    <p>@asset_label@ - @asset_description@</p>
    <h2>@asset_title;noquote@</h2>
  </if>
</if>

<if @has_bg_image_p@ true>
<div style="background-color: transparent; background-repeat: no-repeat; background-image: url(@bg_image_url@); background-size: 100% 100% ; padding: 0 ; margin: 0;">
  <div style="padding-top: 10%; margin-top: 10%;padding-bottom: 10%; margin-bottom: 10%;">
  <div style="padding: 10%; margin: 10%;">
</if>
    <if @label@ not nil>
      <h3>@label@</h3>
    </if>

  <div style="background-color: white ; padding: 0 ; margin: 0 ; padding: 1%; margin: 1%;">
    <ul>
      @content;noquote@
    </ul>  
  </div>
<if @has_bg_image_p@ true>
  </div>
</div>
</div>
</if>

