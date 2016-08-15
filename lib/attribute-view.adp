
<if @sub_type_id_url@ not nil>
  <img src="resources/icons/@sub_type_id_url@.png" title="@sub_asset_title;noquote@" alt="@sub_asset_title;noquote@">
  <if @sub_asset_label@ not nil>
    <p>@sub_asset_label@ - @sub_asset_description@</p>
    <h2>@sub_asset_title;noquote@</h2>
  </if>
  <div style="background-color: transparent; background-repeat: no-repeat; background-image: url(resources/icons/@sub_type_id_url@-background.png); background-size: 100% 100% ; padding: 0 ; margin: 0;">
  <div style="padding-top: 10%; margin-top: 10%;padding-bottom: 10%; margin-bottom: 10%;">
  <div style="padding: 10%; margin: 10%;">
</if><else>
  <div style="background-color: white ;">
  <div style="padding: 0 ; margin: 0 ;">
  <div style="padding: 1%; margin: 1%;">
</else>

<if @sub_label@ not nil>
  <h3>@sub_label@ (@sub_type_id@)</h3>
</if><else>
  <h3>@sub_type_id@</h3>
</else>

<ul>
  @content;noquote@
</ul>  

</div>
</div>
</div>
