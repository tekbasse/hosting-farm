<master>
  <property name="doc(title)">@title@</property>
  <property name="title">@title@</property>
  <property name="context">@context;noquote@</property>


<h1>@title@</h1>
<if @user_message_html@ not nil>
<ul>
  @user_message_html;noquote@
</ul>
</if>

<if @gt1_user_p@ true>

<!-- one col on l, m, s  -->
<div class="l-grid-whole m-grid-whole s-grid-whole padded">
  <div class="content-box">
  <include src="/packages/hosting-farm/lib/users-view" &users_lists=users_lists &perms_arr=perms_arr s="@s;noquote@" p="@p;noquote@" this_start_row="@this_start_row;noquote@" base_url="@base_url;noquote@">

  </div>
</div>

<if @form_html@ not nil>
 @form_html;noquote@
</if>


