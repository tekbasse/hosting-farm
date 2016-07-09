<master>
<property name="doc(title)">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<h1>Internal conventions</h1>
<h3>year 2038 problem statement</h3>
<p>
Table hf_monitor's report_id uses machine time in seconds 
 instead of tcl scan to manage times for delta t values in the logs.
All related database fields use big int format.
This means 
 <a href="https://en.wikipedia.org/wiki/Year_2038">Year 2038 issues</a>
 are not expected with this system.
</p>
<h2>Assets and attributes</h2>
<p>
Assets are objects that are designed to be tracked for general administration and billing.
</p><p>
Attributes are assigned to objects to assist with administering.
Each attribute has a set of attribute related parameters.
</p><p>
Each asset may have one primary attribute assigned to it, and as many other attributes as required.
</p><p>
Revisioning is provided to assist in showing an overview of change history
 mainly for administrative and diagnostics purposes.
</p>
<h3>Assets</h3>
<p>
Assets have revisioning provided via table hf_asset_rev_map. 
Each asset is assigned an asset_id, which is also its revision reference.
The first asset_id of an asset becomes its permanent reference id.
See table hf_assets.f_id
</p><p>
Assets can consist of attributes and other assets. 
In a tree analogy, assets are branches. 
Leaves are attributes.
</p>
<h3>Attributes</h3>
<p>
Attributes are a set of parameters related to a specific administrative area.
Each administrative area has a separate table of parameters:
</p>
<table><tr>
<td>administrative area</td><td>table name</td>
</tr><tr>
<td>Data centers</td><td>hf_data_centers</td>
</tr><tr>
<td>Hardware</td><td>hf_hardware</td>
</tr><tr>
<td>Virtual machines</td><td>hf_virtual_machine</td>
</tr><tr>
<td>Virtual hosts</td><td>hf_vhosts</td>
</tr><tr>
<td>NS records</td><td>hf_ns_records</td>
</tr><tr>
<td>Network interfaces</td><td>hf_network_interfaces</td>
</tr></table>
<p>
See <a href="data-model">data model</a> for a more complete list with detail.
</p><p>
Attributes are assigned to an asset (or possibly another attribute) via table hf_sub_asset_map. 
In a tree analogy, assets are branches, leaves are attributes, and leaves may have leaves, too. 
See <a href="/api-doc/proc-view?proc=hf_types_allowed_by">hf_types_allowed_by</a>
 for assignment restrictions.
 Existing attribute types are in <a href="/api-doc/proc-view?proc=hf_asset_type_id_list">hf_asset_type_id</a>.
 This arrangement can be extended to any number of new attributes without requiring a complete code re-write.
</p><p>
Attributes are assigned a sub_f_id and a sub_label.
Each revision assigns a new sub_f_id and 
 marks the old attribute table record as trashed, 
 usually a time_trashed timestamp in the attribute table.
An attribute's sub_label is a way to track an attribute between revisions.
This provides a way for attribute assignments to adapt
 to administrative circumstances, such as when switching 
 the primary network interface of hardware, without having
 to rebuild an asset-attribute tree.
A trashed_p flag in hf_sub_asset_map is marked true when an attribute is no longer available.
</p>
<h3>Primary asset attribute pair</h3>
<p>
If an asset is of a type described in the <a href="data-model">data model</a>
  then it is usually assigned an attribute where related details are stored.
For example,  a #hosting-farm.vm# (#hosting-farm.virtual_machine# ) attribute adds details to a record
  in table hf_virtual_machines.
</p><p>
Attribute parameters are passed to underlying adminstrative procedures when needed, so
 attributes can be referebced by sub_label, asset's f_id, asset_type_id etc. 
Each attribute type has a sort order assigned to it. See hf_sub_asset_map.sub_sort_order
Priority is given to the first one assigned. Sort order can be revised as needed.
</p>
<h2>General API</h2>
<p>
Documentation for API is provided via searchable OpenACS API Browser.
The api is separated into topics by filename. See <a href="/api-doc/package-view?version_id=@pkg_version_id@">ACS API Browser for Hosting Farm</a>
</p>


