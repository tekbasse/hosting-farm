# hosting-farm/lib/resource-status-summary-1.tcl
# requires eop_ts
# requires eopp_ts
# optional: now_ts
# eop is end of period (timestamp in seconds)
# eopp is end of previous period (timestamp in seconds)
# now is current time (timestamp in seconds)

if { ![info exists now] } {
    set now [clock seconds]
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

set days_per_period 
# 1 TB = 1 000 000 000 000
 [list HW Traffic 102400000000 136.69 GB 146.67 GB]
 [list HW Storage 10.00 TB 2.37 TB 3.25 TB]
 [list HW Memory 768.00 GB 537.00 GB 580.00 GB]
 [list VM Traffic 1024 GB 136.69 MB 146.67 MB]
 [list VM Storage 10.00 GB 2.37 GB 3.25 GB]
 [list VM Memory 768.00 MB 537.00 MB 580.00 MB]
 [list SS Traffic 1024 MB 136.69 KB 146.67 KB]
 [list SS Storage 10.00 MB 2.37 MB 3.25 MB]
 [list SS Memory 768.00 KB 537.00 KB 580.00 KB]
