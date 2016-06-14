# hosting-farm/lib/assets.tcl
# show a list of hf assets
#

# to pass array via include, see: /doc/acs-templating/tagref/include
# ie: &local_arr_name="calling_page_arr_name"
#
# Array expects..
# up to one key per asset_type_id, or
# all_types combined in the element "all"

# This allows sql in calling page to easily scope and limit list
# using pagination-bar

# @see hosting-farm/lib/pagination-bar.tcl for lists pagination menu
# @param base_url is url for page (required)
# @param item_count (required)
# @param items_per_page (required)
# @param this_start_row (required) the start row for this page
# @param separator is html used between page numbers, defaults to &nbsp;


set content "[llength $x] $x"