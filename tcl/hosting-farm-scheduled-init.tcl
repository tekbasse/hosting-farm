# hosting-farm/tcl/hosting-farm-scheduled-init.tcl

# Schedule recurring procedures

# @creation-date 2014-09-12


# Scheduled proc scheduling:
# Nightly pi time + 1 = 4:14am

#ns_schedule_daily -thread 4 14 hf::proc...

# once every 1/3 minute.
set frequent_base [expr 13 * 1]

ad_schedule_proc -thread t $frequent_base hf::schedule_do
