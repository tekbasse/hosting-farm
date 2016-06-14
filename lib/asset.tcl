# hosting-farm/lib/asset.tcl
# show a list of hf asset
#

# requires:
# @param array with elements of hf_asset_keys
# optional:
#

# to pass array via include, see: /doc/acs-templating/tagref/include
# ie: &asset_arr="calling_page_arr_name"
#
#
# 
qf_array_to_vars asset_arr [hf_asset_keys ]
