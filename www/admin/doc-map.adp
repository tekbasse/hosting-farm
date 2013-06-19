<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>

<p>Under development. See <a href="notes.txt">notes.txt</a>.</p>
<pre>
www/admin
  customer resources
   support categories
   canned responses
  config assets
   accounting
     reports
     generate invoice(s)
   db server
   vm/vh features
   vm templates
   data center templates
 view/add/edit/monitoring/inactivate:
   data centers
     switches
       ip addresses
     servers (including db servers)
       active_p, ip_number, domain (add, edit, disable, delete)
     vms
       users
     vh
       users
     databases
       users

     
www/
  asset-templates
  asset-new (from templates)
  asset-list/edit
    db edit
    vm edit
      dlz-manage (view/edit/add) # dlz - dynamically load domain name zone
      vh edit
      
  client-permissions-view-edit
  support
     issues  view active-all/add/edit
  accounting
     statements
     pay invoice
     advance_pay / extend
     transfer credit
     contract management
     incomplete-activation.php
     referrals
     usage summary
     
     
     

</pre>
