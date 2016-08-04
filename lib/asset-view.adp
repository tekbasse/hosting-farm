
<if @asset_type_id@ not nil>
  <img src="/resources/icons/@asset_type_id@.png" title="@name;noquote@" alt="@name;noquote@">
</if>

<div style="background: url (/resources/icons/@asset_type_id@-background.png); background-size: contain;">
<if @label@ not nil>
  <h3>@label@</h3>
  <p>@title@</p>
  
  <ul>
    <if @detail_p@>
      <li>
        qal_product_id @qal_product_id@
      </li><li>
        publish_p      @publish_p@
      </li><li>
        monitor_p      @monitor_p@
      </li><li>
        trashed_p      @trashed_p@
      </li>
    </if>
    
    <if @tech_p@>
      <li>
        op_status   @op_status@
      </li><li>
        template_p  @template_p@
      </li><li>
        templated_p @templated_p@
      </li><li>
        triage_priority @triage_priority@
      </li>
    </if>
  </ul>
</if>
