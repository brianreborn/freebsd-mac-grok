# Orthogonal MAC modules (not mac_lomac(4))

Source of truth for **freebsd-mac-generic**. All are in GENERIC via `options MAC` (**mac(4)**). Load with **loader.conf(5)** `*_load="YES"` or **kldload(8)**.

| Module | Labels? | Loader | Typical sysctl / rc | Orthogonality |
| --- | --- | --- | --- | --- |
| **mac_seeotheruids(4)** | no | `mac_seeotheruids_load` | `security.mac.seeotheruids.enabled`, `.specificgid_enabled`, `.specificgid`, `.primarygroup_enabled` | Hide other UIDs’ processes/sockets. Exempt a GID (often `wheel`=0). |
| **mac_ifoff(4)** | no | `mac_ifoff_load` | `security.mac.ifoff.lo_enabled`, `.bpfrecv_enabled`, `.other_enabled` | Silence interfaces at boot / on tripwire. Easy to cut SSH. |
| **mac_portacl(4)** | no | `mac_portacl_load` | `security.mac.portacl.enabled`, `.rules`, `.suser_exempt`, `.port_high`; often `net.inet.ip.portrange.reservedlow=0` | Allow non-root bind to listed ports. |
| **mac_bsdextended(4)** | no | `mac_bsdextended_load` | **rc.conf(5)** `ugidfw_enable`, rules via **ugidfw(8)** / `/etc/rc.bsdextended` | File-system firewall. Empty ruleset = allow all. |
| **mac_partition(4)** | yes | `mac_partition_load` | `security.mac.partition.enabled`; **login.conf(5)** `label=partition/N` | Process partitions. Needs labels; heavier than seeotheruids. |
| **mac_ipacl(4)** | no | `mac_ipacl_load` | see **mac_ipacl(4)** | IP address ACL. |
| **mac_do(4)** | no | `mac_do_load` | see **mac_do(4)** | Constrain setuid/setgid-style credential changes. |
| **mac_priority(4)** | no | `mac_priority_load` | see **mac_priority(4)** | Priority / nice policy. |

Do **not** load **mac_biba(4)** or **mac_mls(4)** alongside **mac_lomac(4)** unless the user explicitly wants a second information-flow proof. Do not load **mac_test(4)** / **mac_stub(4)** / **mac_none(4)** on a real host.

Default recommendation with LOMAC: **mac_seeotheruids(4)** only, `specificgid` = `wheel` (0) so operators still see the box.

Known issues (Handbook troubleshooting, seeotheruids vs root PRs, ifoff lockout, ugidfw new-user reload, partition unload): skill `README.md` § Known issues. Do not omit that section from the result README.

---
Copyright © 2026 Brian Fundakowski Feldman. Light-ware License — see the repository root [LICENSE](https://github.com/brianreborn/freebsd-mac-grok/blob/main/LICENSE) and [NOTICE.md](https://github.com/brianreborn/freebsd-mac-grok/blob/main/NOTICE.md).

