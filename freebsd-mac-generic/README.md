# freebsd-mac-generic

Orthogonal **mac(4)** modules **other than** **mac_lomac(4)**. Same rc.d/uninstall pattern as LOMAC, **without** ZFS snapshots — the **freebsd-mac** umbrella takes those before and after the whole suite.

## Invoke

`/freebsd-mac-generic` or “enable seeotheruids”, “hide other users’ processes”, **ugidfw(8)**, **mac_portacl(4)**.

## Result → package

```
/usr/local/etc/rc.d/mac_generic_grok
/usr/local/etc/mac_generic_grok/POLICIES
/usr/local/etc/mac_generic_grok/POLICY
/var/db/mac_generic_grok/PREINSTALL/
```

```sh
sudo ~/freebsd-mac-generic/mac_generic_grok oneinstall
sudo service mac_generic_grok onestage
sudo service mac_generic_grok onestart
sudo service mac_generic_grok oneupdate    # later
sudo service mac_generic_grok oneuninstall
```

`POLICIES`: one name per line (`seeotheruids`, `ifoff`, `portacl`, `bsdextended`, `partition`, `ipacl`, `do`, `priority`). See `references/catalog.md`.

## Defaults

- Recommended with LOMAC: **mac_seeotheruids(4)** only, `SEEOTHERUIDS_EXEMPT_GID=0` (`wheel`).
- **mac_ifoff(4)** stanza leaves `other_enabled=0` (non-loopback down until you change it) — do not enable blindly on a remote box.
- **mac_bsdextended(4)** also sets **rc.conf(5)** `ugidfw_enable`; empty ruleset allows all (**ugidfw(8)**).

## Uninstall

Restores **loader.conf(5)** / **rc.conf(5)** from PREINSTALL, **kldunload(8)**s listed modules. Does not touch LOMAC or ZFS.

## Known issues (official docs and mailing lists)

Leave this section in the **result** README. Status as of 2026-08. LOMAC-specific issues live in the **freebsd-mac-lomac** README; this catalog is the orthogonal modules.

### Official — Handbook ch.19 and manuals

Handbook [§19.5](https://docs.freebsd.org/en/books/handbook/mac/#mac-policies), [§19.6 User Lock Down](https://docs.freebsd.org/en/books/handbook/mac/#mac-userlocked), [§19.8 Troubleshooting](https://docs.freebsd.org/en/books/handbook/mac/#mac-troubleshoot). Chapter examples are **not** production policy.

| Issue | Source | What happens | What this package does |
| --- | --- | --- | --- |
| MAC over SSH | Handbook §19.4 | Easy to lock yourself out | Default POLICIES is **mac_seeotheruids(4)** only. **mac_ifoff(4)** is opt-in |
| `mac_ifoff(4)` silences non-loopback | Handbook §19.5.3; **mac_ifoff(4)** | `security.mac.ifoff.other_enabled=0` (this package’s stanza) drops SSH/ethernet at boot | Refuse blind enable on a remote box; keep a console; `lo_enabled` stays on |
| `mac_seeotheruids(4)` vs `root` | Handbook §19.6: “Do not try to test with the `root` user unless the specific sysctls have been modified”; **mac_seeotheruids(4)** `suser_privileged` | Root may still see everyone, *or* (if that OID is 0) root is hidden from itself in surprising ways | Default exempt GID is `0` (`wheel`) via `specificgid`. Do not test hide-other-UIDs while logged in as root without reading the sysctls |
| `specificgid` is **one** GID | Handbook §19.5.1; **mac_seeotheruids(4)** | There is no list. `primarygroup_enabled` **must not** be set together with `specificgid_enabled` | `SEEOTHERUIDS_EXEMPT_GID` is a single number. Put operators in **one** group (usually `wheel`) |
| `mac_bsdextended(4)` empty ruleset | Handbook §19.5.2 | “By default, no rules are defined and everything is completely accessible” | Empty **ugidfw(8)** is allow-all. Do not claim “file-system firewall is on” until rules exist |
| `firstmatch_enabled` | Handbook §19.5.2 / **mac_bsdextended(4)** | Rule walk is first-match or last-match depending on the sysctl | Do not generate a dual-meaning ruleset; document which |
| New users missing ugidfw rules | Handbook §19.6 | “When a new user is added, their mac_bsdextended rule will not be in the ruleset… unload and reload” | `oneupdate` / reload path; warn to **kldunload(8)**/**kldload(8)** or restart the service after `pw useradd` |
| `mac_partition(4)` breaks Xorg / `top` | Handbook §19.5.5, §19.8 | Insecure class cannot spawn `top` or start X; “Users can see processes in root's label unless seeotheruids is loaded” | Prefer seeotheruids. Partition needs **login.conf(5)** labels — do not mix with LOMAC unless the user insists |
| `mac_portacl(4)` still blocked by IP portrange | Handbook §19.5.4 | Non-root bind to &lt;1024 also needs `net.inet.ip.portrange.reservedlow=0` (and `reservedhigh`) | Document both knobs; do not enable portacl as a surprise on a box that must not bind 80 as `www` |
| Xorg / `_secure_path` / `whoami` 0 | Handbook §19.8 | Same as LOMAC/Biba if any *labeled* module is also loaded | This skill does not write LOMAC labels. If LOMAC is also installed, those Handbook symptoms are LOMAC’s |
| Framework experimental | **mac(9)** / **mac_seeotheruids(4)** BUGS | “MAC Framework policies should not be relied on, in isolation, to protect against a malicious privileged user” | seeotheruids hides processes; it is not a jail |

### Apocryphal — mailing lists, PRs, forums

| Issue | Source | What happens | What this package does |
| --- | --- | --- | --- |
| Root vs seeotheruids, both directions | **freebsd-bugs** listings 2004–2006: kern/72263 “mac_seeotheruids restricts root”; bin/79714 “mac_seeotheruids not blocking root” | Early PRs argued both “root is wrongly hidden” and “root is wrongly visible.” Current knob is `security.mac.seeotheruids.suser_privileged` | Set `suser_privileged` explicitly in POLICY; default leaves operators in the exempt GID rather than depending on the suser bit |
| Multiple exempt GIDs | FreeBSD Forums [thread 76153](https://forums.freebsd.org/threads/how-to-manage-multiple-uid-gid-in-mac-seeotheruids-specificgid.76153/) (2020) | `specificgid` cannot be a list; “create one group and add the users” | Same: one exempt group |
| `mac_partition(4)` **kldunload(8)** | Early TrustedBSD tutorial traffic: unload returning error 12 (`ENOMEM`) while partition labels still in memory | Module stays loaded; `uninstall` looks like it failed | `enabled=0` first; then unload. Prefer not loading partition |
| Do not load **mac_biba(4)** / **mac_mls(4)** next to LOMAC | Handbook planning + **mac_lomac(4)** | Combined labels, impossible proofs | Catalog forbids them unless the user explicitly wants a second flow policy |
| **mac_test(4)** / **mac_stub(4)** / **mac_none(4)** | Handbook §19.1 | Development/test modules | Never on a real host |

## See also

**mac(4)**, **mac_seeotheruids(4)**, **mac_ifoff(4)**, **mac_portacl(4)**, **mac_bsdextended(4)**, **ugidfw(8)**, **mac_partition(4)**, **loader.conf(5)**, **sysctl(8)**, **kldload(8)**, FreeBSD Handbook [ch.19](https://docs.freebsd.org/en/books/handbook/mac/) ([§19.8](https://docs.freebsd.org/en/books/handbook/mac/#mac-troubleshoot)), **freebsd-mac-lomac** (LOMAC Known issues), **freebsd-mac**.
