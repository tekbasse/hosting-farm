<master>


<if @app_admin_p@>
  <a href="admin/">#accounts-ledger.admin#</a>
</if>

<if @gt1_customer_p@>
  <a href="c">#accounts-ledger.Customers#</a>
</if>

<if @technical_p@ or @main_p@ or @site_developer@>
  <a href="assets">#accounts-ledger.Assets#</a>
</if>

<if @billing_p@ or @main_p@>
  <a href="billing">#accounts-ledger.Accounts#</a>
</if>

