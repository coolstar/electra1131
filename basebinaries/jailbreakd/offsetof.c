
unsigned offsetof_p_pid = 0x10;               // proc_t::p_pid (good on 11.3)
unsigned offsetof_task = 0x18;                // proc_t::task (good on 11.3)
unsigned offsetof_p_uid = 0x30;               // proc_t::p_uid (good on 11.3)
unsigned offsetof_p_gid = 0x34;               // proc_t::p_uid (good on 11.3)
unsigned offsetof_p_ruid = 0x38;              // proc_t::p_uid (good on 11.3)
unsigned offsetof_p_rgid = 0x3c;              // proc_t::p_uid (good on 11.3)
unsigned offsetof_p_ucred = 0x100;            // proc_t::p_ucred (good on 11.3)
unsigned offsetof_p_csflags = 0x2a8;          // proc_t::p_csflags (good on 11.3)
unsigned offsetof_itk_self = 0xD8;            // task_t::itk_self (convert_task_to_port)
unsigned offsetof_itk_sself = 0xE8;           // task_t::itk_sself (task_get_special_port)
unsigned offsetof_itk_bootstrap = 0x2b8;      // task_t::itk_bootstrap (task_get_special_port)
unsigned offsetof_itk_space = 0x308;          // task_t::itk_space
unsigned offsetof_ip_mscount = 0x9C;          // ipc_port_t::ip_mscount (ipc_port_make_send)
unsigned offsetof_ip_srights = 0xA0;          // ipc_port_t::ip_srights (ipc_port_make_send)
unsigned offsetof_ip_kobject = 0x68;          // ipc_port_t::ip_kobject
unsigned offsetof_p_textvp = 0x248;           // proc_t::p_textvp (good on 11.3)
unsigned offsetof_p_textoff = 0x250;          // proc_t::p_textoff
unsigned offsetof_p_cputype = 0x2c0;          // proc_t::p_cputype
unsigned offsetof_p_cpu_subtype = 0x2c4;      // proc_t::p_cpu_subtype
unsigned offsetof_special = 2 * sizeof(long); // host::special
unsigned offsetof_ipc_space_is_table = 0x20;  // ipc_space::is_table?..

unsigned offsetof_ucred_cr_uid = 0x18;        // ucred::cr_uid (good on 11.3)
unsigned offsetof_ucred_cr_ruid = 0x1c;       // ucred::cr_ruid (good on 11.3)
unsigned offsetof_ucred_cr_svuid = 0x20;      // ucred::cr_svuid (good on 11.3)

unsigned offsetof_v_type = 0x70;              // vnode::v_type (good on 11.3)
unsigned offsetof_v_id = 0x74;                // vnode::v_id (good on 11.3)
unsigned offsetof_v_ubcinfo = 0x78;           // vnode::v_ubcinfo (good on 11.3)

unsigned offsetof_ubcinfo_csblobs = 0x50;     // ubc_info::csblobs (good on 11.3)

unsigned offsetof_csb_cputype = 0x8;          // cs_blob::csb_cputype (good on 11.3)
unsigned offsetof_csb_flags = 0xc;           // cs_blob::csb_flags (good on 11.3)
unsigned offsetof_csb_base_offset = 0x10;     // cs_blob::csb_base_offset (good on 11.3)
unsigned offsetof_csb_entitlements_offset = 0x98; // cs_blob::csb_entitlements (good on 11.3)
unsigned offsetof_csb_signer_type = 0xA0;     // cs_blob::csb_signer_type (good on 11.3)
unsigned offsetof_csb_platform_binary = 0xA4; // cs_blob::csb_platform_binary (good on 11.3)
unsigned offsetof_csb_platform_path = 0xA8;   // cs_blob::csb_platform_path (good on 11.3)

unsigned offsetof_t_flags = 0x3a0; // task::t_flags
