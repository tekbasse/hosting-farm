<master>
  <property name="doc(title)">@title@</property>
  <property name="title">@title@</property>
  <property name="context">@context;noquote@</property>


<if @menu_html@ not nil>
  <div style="text-align: right; margin: 0; padding: 0;">@menu_html;noquote@</div>
</if>
<h1>@title@</h1>
<if @user_message_html@ not nil>
<ul>
  @user_message_html;noquote@
</ul>
</if>

<if @include_view_assets_p@ true>

<!-- one col on l, m, s  -->
<div class="l-grid-whole m-grid-whole s-grid-whole padded">
  <div class="content-box">
  <include src="/packages/hosting-farm/lib/assets-view-2" &assets_lists=assets_lists interval_remaining="@interval_remaining;noquote@" s="@s;noquote@" p="@p;noquote@" this_start_row="@this_start_row;noquote@" base_url="assets">

  </div>
</div>






</if>
<if @include_view_one_p@ true>
  <include src="/packages/hosting-farm/lib/asset-view" &asset_arr=obj_arr>
</if>
<if @include_view_attrs_p@ true>
  <include src="/packages/hosting-farm/lib/attributes-view" &attrs_lists=attrs_lists>
</if>
<if @include_view_sub_assets_p@ true>
<!-- make a revision of assets-view-2 for use with scope of sub_assets_list -->
  <include src="/packages/hosting-farm/lib/sub-assets-view" &sub_assets_lists=sub_assets_lists>
</if>

<if @form_html@ not nil>
 @form_html;noquote@
</if>


