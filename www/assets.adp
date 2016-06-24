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

<if @include_view_multiple_p@ not nil>
  <include src="/packages/hosting-farm/lib/view-multiple" &assets_lists=assets_lists>
</if>
<if @include_view_one_p@ not nil>
  <include src="/packages/hosting-farm/lib/view-one" &asset_arr=obj_arr>
</if>

<if @form_html@ not nil>
 @form_html;noquote@
</if>


