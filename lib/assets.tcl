# hosting-farm/lib/assets.tcl
# show a list of hf assets
#
# requires:
# assets_lists  As if from a db_lists_of_lists query hf_assets
#               where elements are returned in order of hf_asset_keys
# 


# to pass array (or lists) via include: /doc/acs-templating/tagref/include
# ie: &local_arr_name=calling_page_arr_name
# or: &local_lists_name=calling_page_lists_name
#


# all_types combined in the element "all"


# This allows sql in calling page to easily scope and limit list
# using pagination-bar

# @see hosting-farm/lib/pagination-bar.tcl for lists pagination menu
# @param base_url is url for page (required)
# @param item_count (required)
# @param items_per_page (required)
# @param this_start_row (required) the start row for this page
# @param separator is html used between page numbers, defaults to &nbsp;

# assets_lists \[hf_asset_ids_for_user $user_id\]
set content "[llength $x] $x"



#  see hosting-farm/doc/assets.??? for code