# hosting-farm/tcl/hosting-farm-scheduled-init.tcl

# Schedule recurring procedures

#    @creation-date 2014-09-12
#    @Copyright (c) 2014 Benjamin Brink
#    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
#    @project home: http://github.com/tekbasse/hosting-farm
#    @address: po box 20, Marylhurst, OR 97036-0020 usa
#    @email: tekbasse@yahoo.com


# Scheduled proc scheduling:
# Nightly pi time + 1 = 4:14am

#ns_schedule_daily -thread 4 14 hf::proc...

# once every 1/3 minute.
set frequent_base [expr 13 * 1]

ad_schedule_proc -thread t $frequent_base hf::schedule_do