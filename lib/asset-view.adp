
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
  <if @include_view_attrs_p@ true>
    <include src="/packages/hosting-farm/lib/attributes-view" &attrs_list=attrs_list base_url="@base_url;noquote@" &perms_arr=perms_arr asset_id="@asset_id@">
  </if>
</div>

<if @has_bg_image_p@ true>
      </div>
    </div>
  </div>
</if>

<if @include_view_sub_assets_p@ true>
  <!-- make a revision of assets-view-2 for use with scope of sub_assets_list -->
  <!-- one col on l, m, s  -->
  <div class="l-grid-whole m-grid-whole s-grid-whole padded">
    <div class="content-box">
      <include src="/packages/hosting-farm/lib/assets-view-2" &assets_lists=assets_lists  base_url="@base_url;noquote@" pagination_bar_p="0" &perms_arr=perms_arr asset_id="@asset_id@"  mapped_f_id="@mapped_f_id@">
    </div>
  </div>
</if>

