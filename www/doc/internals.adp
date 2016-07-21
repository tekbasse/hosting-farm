<master>
<property name="doc(title)">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<h1>Internal conventions</h1>

<p>
#hosting-farm.Hosting_Farm# helps manage servers as assets.
Assets can be assigned attributes that convey information in the managing process.
Assets and attributes can be adapted into most any existing organization,
including no organization at all.
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
Attributes are assigned to an asset 
(or possibly another attribute) via table hf_sub_asset_map. 
In a tree analogy, assets are branches, 
 leaves are attributes, and leaves may have leaves, too. 
A leaf needs a leaf for example, 
 when a vhost is issued it's own user account on a virtual machine,
 and there are multiple vhosts hosted on the same vm.
The api also supports adding branches to a leaf, in case you want to.
See 
 <a href="/api-doc/proc-view?proc=hf_types_allowed_by">hf_types_allowed_by</a>
 for assignment restrictions.
 Existing attribute types are in 
 <a href="/api-doc/proc-view?proc=hf_asset_type_id_list">hf_asset_type_id</a>.
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
A trashed_p flag in hf_sub_asset_map is marked true 
 when an attribute is no longer available.
</p>
<h3>Primary asset attribute pair</h3>
<p>
If an asset is of a type described in the <a href="data-model">data model</a>
  then it is usually assigned an attribute where related details are stored.
For example, 
 a #hosting-farm.vm# (#hosting-farm.virtual_machine# ) attribute adds details 
 to a record in table hf_virtual_machines.
</p><p>
Attribute parameters are passed to underlying administrative procedures when 
 needed, 
 so attributes can be referenced by sub_label, 
 asset's f_id, asset_type_id etc. 
Each attribute type has a sort order assigned to it. 
See hf_sub_asset_map.sub_sort_order.
Priority is given to the first one assigned. 
Sort order can be revised as needed.
</p>
<h2>General API</h2>
<p>
Documentation for API is provided via searchable OpenACS API Browser.
The api is separated into topics by filename. 
See 
 <a href="/api-doc/package-view?version_id=@pkg_version_id@">ACS API Browser for Hosting Farm</a>
 detail.
</p><p>
Alternately, here is an overview of API:
</p>
<ul>
<li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/app-procs.tcl">Web-based alert api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-asset-biz-procs.tcl">Asset business logic api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-asset-view-procs.tcl">Asset views api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-asset-util-procs.tcl">Asset utilities api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-attr-biz-procs.tcl">Attribute business logic api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-attr-view-procs.tcl">Attribute views api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-biz-procs.tcl">General business logic api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-monitor-procs.tcl">System monitors api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-monitor-procs.tcl">Admin (without connection) api</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-monitor-procs.tcl">Permissions api</a>
</li>
</ul>
<p>
Customization to the system is expected the default file, and by copying and modifying the example api interface file to a new name:
</p>
<ul>
<li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-defaults-procs.tcl">System defaults</a>
</li><li>
<a href="/api-doc/procs-file-view?version_id=@pkg_version_id@&path=packages/hosting-farm/tcl/hosting-farm-local-ex-procs.tcl">Example api interface to local maintenance libraries</a>
</li>
</ul>
<p>
Be sure to end any new filenames with *-proc.tcl 
 so the package manager will read it. 
By using a different name than existing filenames, 
 your customizations will not be clobbered
 if and when you decide to upgrade the package.
</p>
<h3>year 2038 problem statement</h3>
<p>
Table hf_monitor's report_id uses machine time in seconds 
 instead of tcl scan to manage times for delta t values in the logs.
All related database fields use big int format.
This means 
 <a href="https://en.wikipedia.org/wiki/Year_2038">Year 2038 issues</a>
 are not expected with this system.
</p>
<p>
By the way, 
 OpenACS has support for all sorts of automated possibilities with 
 site management. 
See <a hef="/api-doc/">ACS API Browser</a>.
</p>
<pre>
Here a summary of some early api notes:

UI app procs in app-procs.tcl
hf_log_create (via batch process)
hf_log_read

UI batch processor API
hf::schedule::do
hf::schedule::add
hf::schedule::trash
hf::schedule::read
hf::schedule::list

General Asset UI in hosting-farm-asset-procs.tcl
hf_asset_id_exists 
hf_change_asset_id_for_label
hf_asset_rename
hf_asset_id_from_label 
hf_asset_label_from_id 
hf_asset_label_id_from_template_id 
hf_asset_from_label 
hf_asset_create 
hf_asset_stats 
hf_assets 
hf_asset_read 
hf_asset_write
hf_asset_delete
hf_asset_trash

The monitoring process

monitor batch processor API
hf::monitor::check
hf::monitor::do
hf::monitor::add
hf::monitor::trash
hf::monitor::read
hf::monitor::list



hosting-farm-local-ex-procs.tcl:ad_proc -private hfl_allow_q
hosting-farm-local-ex-procs.tcl:ad_proc -private hfl_asset_halt_example

hosting-farm-procs.tcl:ad_proc -private hf_vm_quota_read

monitoring processes are automatically considered periodic, and added using hf::monitor::add

monitor user API:
hf_monitor_configs_write
hf_monitor_configs_read
hf_monitor_logs
hf_monitors_inactivate


A process is called to add to the monitor_log


hf_monitor_update updates table hf_monitor_log

hf_monitor_status returns most recent analyzed monitor_logs from table hf_monitor_status

hf_monitor_statistics analyzes data from unprocessed hf_monitor_update, posts to hf_monitor_status, hf_monitor_freq_dist_curves, and hf_monitor_statistics

hf_monitor_report_read



#   hf_monitor_update         Write an update to a log (this includes distribution curve info, ie time as delta-t)
#   hf_monitor_status         Read status of asset_id, defaults to most recent status (like read, just status number)

#   hf_monitor_statistics     Analyse most recent hf_monitor_update in context of distribution curve
#                             Returns distribution curve of most recent configuration (table hf_monitor_freq_dist_curves)
#                             Save an Analysis an hf_monitor_update (or FLAG ERROR)

#   hf_monitor_logs           Returns monitor_ids of logs indirectly associated with an asset (direct is 1:1 via asset properties)

#   hf_monitor_report         Returns a range of monitor history
#   hf_monitor_status_history  Returns a range of status history

#   hf_monitor_asset_from_id  Returns asset_id of monitor_id


# hf_monitor_alert_create 
# hf_monitor_alert_process
# hf_monitor_alerts_status
# hf_monitor_alert_trash 
</pre>

