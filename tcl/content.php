         $total_cost = 0;
         $total_traffic = 0;
         $total_traffic_est = 0;
         $total_base_traffic = 0;
         $total_bandwidth_cost = 0;
         $total_storage_cost = 0;
         $total_storage = 0;
         $total_database = 0;


          $est_traffic = (total_traffic / $days) * $days_in_month

          $over_traffic = 0

          $total_base_traffic += base_traffic


           if((base_traffic * 1024 * 1024 ) - $est_traffic < 0) {
                       $over_traffic = $est_traffic - ( base_traffic * 1024 * 1024 )
                       
            if(fmod($over_traffic, 1024 * 1024 * x_traffic) == 0)  {
             $over_cnt = $over_traffic / (1024 * 1024 * x_traffic )
            } else {
             $over_cnt = floor($over_traffic / (1024 * 1024 * x_traffic )) + 1
            }

            $bandwidth_cost = $over_cnt * over_traffic
            $total_bandwidth_cost += $bandwidth_cost
           }


          $total_traffic += total_traffic
          $total_traffic_est += $est_traffic




          $over_storage = 0


           if((base_storage * 1024 * 1024 ) - total_storage < 0) {
            $over_storage = total_storage - ( base_storage * 1024 * 1024 )

            if(fmod($over_storage, 1024 * 1024 * x_storage) == 0)  {
             $over_cnt = $over_storage / (1024 * 1024 * x_storage)
            } else {
             if(x_storage == 0) {
              $over_cnt = -1
             } else {
              $over_cnt = floor($over_storage / (1024 * 1024 * x_storage)) + 1
             }
            }

            $storage_cost = $over_cnt * over_storage
            $total_storage_cost += $storage_cost
           }


          $total_storage += total_storage



            current <?= convert_units(total_traffic) ?>
            estimated <?= convert_units($est_traffic) ?>
            quota <?= convert_units(base_traffic * 1024 * 1024) ?>
            overusage  <?= convert_units($over_traffic) ?>
            extra cost <?= sprintf("%.2f", $bandwidth_cost) ?>

            current <?= convert_units(total_storage) ?>
            quota <?= convert_units(base_storage * 1024 * 1024) ?>
            overusage <?= convert_units($over_storage) ?>
            Extra Cost <?= printf("%.2f", $storage_cost) ?>

         <?= convert_units($total_traffic) ?>
         <?= convert_units($total_traffic_est) ?>
         <?= convert_units($total_base_traffic * 1024 * 1024) ?>
         <?= convert_units($total_storage) ?>
         <?= printf("%.2f", $total_traffic_cost + $total_storage_cost) ?>
