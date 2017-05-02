set title "Hosting Farm Glossary"
set context [list [list index "Documentation"] $title]

set t_list [list \
                Asset \
                Attribute\
                Primary_attribute\
                active_p\
                affix\
                attribute_p\
                base_memory\
                base_storage\
                base_traffic\
                bia_mac_address\
                brand\
                config_uri\
                created\
                cumulative_pct\
                delta_x\
                description\
                details\
                domain_name\
                expected_health\
                expected_percentile\
                feature_type\
                flags\
                halt_proc\
                health_average\
                health\
                health_max\
                health_median\
                health_min\
                health_p0\
                health_p1\
                health_percentile\
                id\
                ipv4_addr\
                ipv4_addr_range\
                ipv4_status\
                ipv6_addr\
                ipv6_addr_range\
                ipv6_status\
                kernel\
                label\
                last_modified\
                max_domain\
                memory_unit\
                monitor_p\
                monitor_y\
                mount_union\
                name\
                name_record\
                op_status\
                orphaned_p\
                os_dev_ref\
                popularity\
                port\
                private_vps\
                proc_name\
                protocol\
                publish_p\
                range_max\
                range_min\
                report\
                report_time\
                reported_by\
                requires_upgrade_p\
                resource_path\
                sample_count\
                server_name\
                service_name\
                significant_change\
                software_as_a_service\
                ss_subtype\
                ss_type\
                ss_ultrasubtype\
                ss_undersubtype\
                start_proc\
                storage_unit\
                sub_label\
                sub_sort_order\
                system_name\
                template_p\
                templated_p\
                time_created\
                time_created\
                time_start\
                time_stop\
                time_trashed\
                traffic_unit\
                trashed_by\
                trashed_p\
                triage_priority\
                ul_mac_address\
                version\
                virtual_host\
                virtual_machine\
                vm_type\
                vmm_memory\
                x_pos\
               ]

set terms_list [list ]
foreach t $t_list {
    lappend terms_list "#hosting-farm.${t}#: #hosting-farm.${t}_def#"
}
set terms_html "<ul><li>"
append terms_html [join $terms_list "</li>
<li>"]
append terms_html "</li></ul>"
