<master>
  <property name="doc(title)">@title@</property>

<if @pkg_admin_p@>
  <a href="admin/">#accounts-ledger.admin#</a>
  <a href="doc/">Documentation</a>
</if>

<if @gt1_customer_p@>
  <a href="c">#accounts-ledger.Customers#</a>
</if>

<if @assets_read_p@>
  <a href="assets">#accounts-ledger.Assets#</a>
</if>

<if @non_assets_read_p@>
  <a href="billing">#accounts-ledger.Accounts#</a>
</if>

