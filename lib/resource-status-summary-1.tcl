# hosting-farm/lib/resource-status-summary-1.tcl
# requires eop_ts
# requires eopp_ts
# optional: 
# now_ts
# period_unit "month"
          
# eop is end of period (timestamp in seconds)
# eopp is end of previous period (timestamp in seconds)
# now is current time (timestamp in seconds)

if { ![info exists now_ts] } {
    set now_ts [clock seconds]
}
if { ![info exists period_unit] } {
    set period_unit "month"
}

# check for compact style
if { ![info exists compact_p ] } {
    set compact_p 0
}

# use percent measurements and faces for compact style

# EOT = end of term
# classic
# asset_type attribute quota current_sample projected_EOT

# compact view: percent of alloted resources
# asset_type attribute pct_of_quota projected_EOT_pct


set seconds_per_period [expr { [clock scan "[clock format $now_ts] + 1 month"] - $now_ts } ]
# from
# HW Traffic 102400000000 136.69 GB 146.67 GB
# HW Storage 10.00 TB 2.37 TB 3.25 TB
# HW Memory 768.00 GB 537.00 GB 580.00 GB
# VM Traffic 1024 GB 136.69 MB 146.67 MB
# VM Storage 10.00 GB 2.37 GB 3.25 GB
# VM Memory 768.00 MB 537.00 MB 580.00 MB
# SS Traffic 1024 MB 136.69 KB 146.67 KB
# SS Storage 10.00 MB 2.37 MB 3.25 MB
# SS Memory 768.00 KB 537.00 KB 580.00 KB

# 1 TB = 1 000 000 000 000
# current projected
set as_lists [list \
              [list HW traffic ] \
              [list HW storage ] \
              [list HW memory ] \
              [list VM traffic ] \
              [list VM storage ] \
              [list VM memory ] \
              [list SS traffic ] \
              [list SS storage ] \
              [list SS memory ]]

set quota_lists [list \
              [list DC traffic 102400000000000] \
              [list DC power 10000000000000] \
              [list DC other 10000000000000] \
              [list HW traffic 102400000000] \
              [list HW storage 10000000000000] \
              [list VM traffic 1024000000000] \
              [list VM storage 10000000000] \
              [list VM memory 768000000] \
              [list SS traffic 1024000000] \
              [list SS storage 10000000] \
              [list SS memory 768000]]


foreach 