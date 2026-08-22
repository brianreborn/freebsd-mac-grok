# freebsd-mac-lomac

Collaborative setup of the FreeBSD **Low-watermark Mandatory Access Control** policy, **mac_lomac(4)**.

This directory is the **skill**. When it runs, it writes a **result directory** that installs as a ports-style **rc.subr(8)** service: `/usr/local/etc/rc.d/mac_lomac_grok`. File labels still come from **setfsmac(8)** and the official specfile; the rc.d script is the wrapper with extra targets (`label`, `checklabels`, `uninstall`, …).

When used **inside** **freebsd-mac**, do not `onesnapshot` here — the umbrella takes **zfs(8)** recursive snapshots (filesystems and zvols) and optional **zpool-checkpoint(8)** before and after the whole suite (`MAC_LOMAC_GROK_SKIP_SNAPSHOT=1`). Standalone LOMAC still offers `onesnapshot` itself.

## Invoke the skill

- Slash: `/freebsd-mac-lomac`
- Menu: `/skills freebsd-mac-lomac`
- Intent: “set up LOMAC”, “MAC labels”, “setfsmac”, “TrustedBSD integrity policy”

The agent will interview you, then emit a result directory. It must **not** `kldload` **mac_lomac(4)** or set `security.mac.lomac.enabled=1` until you open a test window.

## Result directory → installed package

Default result path: `~/freebsd-mac-lomac/`. After `oneinstall`:

```
/usr/local/etc/rc.d/mac_lomac_grok          # rc.subr(8); no .sh
/usr/local/etc/mac_lomac_grok.conf
/usr/local/etc/mac_lomac_grok/
    README
    POLICY
    lomac-policy.contexts
    x11-xorg.contexts                   # Xorg(1) + evdev/hid vs XFree86 sockets
    dev-modern.contexts                 # /dev names: agp→dri/card, evdev, …
    lomac-overlay.contexts
/var/db/mac_lomac_grok/PREINSTALL/          # created on first onestage; never overwritten
```

`mac_lomac_grok_enable` defaults to **NO** (no boot action). `YES` only **kldload(8)**s with `security.mac.lomac.enabled=0` — it does **not** **setfsmac(8)** at boot.

Because enable is NO, use **service(8)** `one*` prefixes:

```sh
sudo ~/freebsd-mac-lomac/mac_lomac_grok oneinstall
sudo service mac_lomac_grok onesnapshot       # extra-safe: zfs snapshot -r (fs + zvol)
# optional pool checkpoint (one per pool; rewind discards later txgs):
#   sudo CHECKPOINT=1 service mac_lomac_grok onesnapshot
sudo service mac_lomac_grok onestage          # config PREINSTALL, then login.conf(5)
sudo service mac_lomac_grok oneupdate         # later: groups/POLICY/contexts + cap_mkdb(1)
sudo service mac_lomac_grok onestart          # kldload, enabled=0; also syncs login classes
sudo service mac_lomac_grok onelabel          # setfsmac(8)
sudo service mac_lomac_grok onechecklabels
sudo service mac_lomac_grok oneenforce        # only when you mean it
```

| Command | Effect |
| --- | --- |
| `install` | Copy package under `/usr/local` |
| `snapshot` | **Offer this first:** `zfs snapshot -r pool@tag` (filesystems and zvols); optional **zpool-checkpoint(8)** |
| `stage` | First time: PREINSTALL + apply config |
| `update` / `reload` | Later: rewrite **login.conf(5)** class block, **cap_mkdb(1)**, sync **pw(8)** groups→classes, refresh `/etc/lomac.contexts`. Does **not** **setfsmac(8)** (warns if contexts hash changed → `onelabel`) |
| `start` / `stop` / `status` | Load/unload **mac_lomac(4)**; `start` also **cap_mkdb(1)** + group→class sync for new members. Never auto-enforce |
| `label` | **setfmac(8)** probe + **setfsmac(8)** `-x` |
| `checklabels` | Read-only sentinels |
| `enforce` / `unenforce` | `security.mac.lomac.enabled` 1 / 0 |
| `uninstall` | Restore **pre-install behavior** (see below) |
| `test*` | Dry-run of the matching command (`teststage`, `testlabel`, `testupdate`, `testuninstall`, …). Prints diffs / `WOULD` lines; changes nothing. Run immediately before the real target. |

## Extra-safe: ZFS snapshots and checkpoints

**Offer `onesnapshot` before `onestage`.** Only ZFS: filesystems, volumes (zvols), optional pool checkpoint. No **bectl(8)**.

| Layer | Command | Rollback |
| --- | --- | --- |
| Recursive snap | `zfs snapshot -r zroot@mac_lomac_grok-pre-…` | `zfs rollback -r zroot@…` (descendant filesystems **and** zvols) |
| Pool checkpoint | `CHECKPOINT=1` → **zpool-checkpoint(8)** | Export/import `--rewind-to-checkpoint`; **discards every txg after the checkpoint**. One checkpoint per pool |

Names: `/var/db/mac_lomac_grok/zfs.snaps`. Skip only with `MAC_LOMAC_GROK_SKIP_SNAPSHOT=1`.

## Uninstall (config restore; use ZFS if you snapshotted)

`uninstall` is the recovery if something breaks and you **did not** take a ZFS snap — or as the first step before `zfs rollback -r`.

It restores **behavior**, not a forensic wipe:

1. `security.mac.lomac.enabled=0` and **kldunload(8)** **mac_lomac(4)** — policy no longer applies, even if MAC xattrs remain on files.
2. Copy back `/boot/loader.conf`, `/etc/login.conf` + `login.conf.db`, `/etc/sysctl.conf`, `/etc/mac.conf`, `/etc/rc.conf` from `/var/db/mac_lomac_grok/PREINSTALL/` (taken **once** on first `stage`, never overwritten).
3. Restore each user’s **login.conf(5)** class from the snapshot (`pw usermod -L`).
4. **pw(8)** `groupdel` only groups this package **created**.
5. Remove `/usr/local/etc/rc.d/mac_lomac_grok` and `/usr/local/etc/mac_lomac_grok/`.
6. **Keep** `PREINSTALL/` so you can see what was restored.

If the snapshot is missing, it still `kldunload`s and strips `# BEGIN mac_lomac_grok` … `# END mac_lomac_grok` stanzas.

```sh
sudo service mac_lomac_grok oneuninstall
```

That is “acting like before”: DAC-only access, original login classes, module not loaded, no boot kld. It is **not** “without a trace” (xattrs and `PREINSTALL/` may remain). A new login drops any in-memory LOMAC process label; the restored **login.conf(5)** is already on disk.

## Manual pages (keep these in scope)

| Topic | Manual |
| --- | --- |
| Policy module | **mac_lomac(4)**, **mac(4)** |
| Label syntax | **maclabel(7)** |
| File labels | **setfmac(8)**, **setfsmac(8)**, **getfmac(8)** |
| Process labels | **setpmac(8)**, **getpmac(8)** |
| User/TTY labels | **login.conf(5)**, **cap_mkdb(1)**, **pw(8)** |
| Boot load | **loader.conf(5)**, **kldload(8)**, **kldstat(8)** |
| Userland label defaults | **mac.conf(5)** |
| Tunables | **sysctl(8)** — `security.mac.lomac.*` |
| UFS multilabel | **tunefs(8)**, **fstab(5)** |
| This package | **mac_lomac_grok(8)**, **mac_lomac_grok(4)**, **mac_lomac_grok.conf(5)**, **mac_lomac_grok(7)** |
| Interfaces | **ifconfig(8)** `maclabel` |
| ZFS | **zfs(8)** `snapshot -r` (fs + zvol), **zpool-checkpoint(8)** |

Read **mac_lomac(4)** before changing grades. LOMAC is an **integrity** policy: a subject that reads a lower-grade object is **demoted** and then cannot write higher-grade objects. That one rule is the proof. Do not stack **mac_mls(4)**, **mac_biba(4)**, or **mac_seeotheruids(4)** unless the user explicitly wants a different problem (secrecy / no-read-down / hide other UIDs). Extra modules do not make LOMAC easier to prove.

## Roles (groups, not accounts)

**login.conf(5)** has no group-to-label map. The skill uses a small, fixed set of **roles**. Each role is one login class plus one **pw(8)** group. Every member of the group gets the same class (`pw usermod user -L class`). Adding someone later is `pw groupmod … -m user` and the same `-L`.

| Role | **pw(8)** group (default) | Login class | **mac_lomac(4)** label | Meaning |
| --- | --- | --- | --- | --- |
| **exempt** | — (root class only) | `root` | `lomac/equal(equal-equal)` | Admin not demoted. Do not put `root` in the other groups. |
| **trusted** | `lomac-trusted` | `trusted` | `lomac/high(low-high)` | Humans who may start at OS integrity (wheel/desktop). Can drop. |
| **sandbox** | `lomac-sandbox` | `sandbox` | `lomac/10[2]` | Agents, builders, guests. Handbook default. New users default here. |

Unlisted users (`DEFAULT_ROLE=sandbox`) get the sandbox class so high is always an explicit group membership. Do not invent a fourth grade unless the interview demands it — LOMAC’s value is few labels and a short proof: *sandbox cannot write-up into high OS objects after a low read*.

## FreeBSD defaults (do not reinvent)

1. **Specfile.** **setfsmac(8)** names `/usr/share/security/lomac-policy.contexts` as the sample PLM (original FreeBSD LOMAC port). Copy that file into the result directory. If the host omitted `share/security` (empty on some installs), use the copy shipped with this skill under `references/lomac-policy.contexts`.

2. **Deploy command.** There is no `rc.d` LOMAC script in base. The documented apply step is:

   ```sh
   setfsmac -f /usr/share/security/lomac-policy.contexts /
   ```

   The Handbook’s Biba/MLS example uses **setfsmac(8)** `-e` (treat unlabeled file systems as errors) and `/etc/policy.contexts`. For LOMAC, keep the official filename and syntax; install the combined spec as `/etc/lomac.contexts` and run **setfsmac(8)** per mount (ZFS datasets are separate trees; `/` then `/home`).

3. **User label.** Handbook **login.conf(5)** example for LOMAC is `lomac/10[2]` (effective 10, auxiliary grade 2). That is the default for a sandbox/unprivileged class unless the interview says otherwise.

4. **mac.conf(5).** Stock `/etc/mac.conf` already lists `?lomac` on file, ifnet, process, and socket. Do not replace the file; append only if `lomac` is missing.

5. **Load.** **mac_lomac(4)** SYNOPSIS: `options MAC` in the kernel (GENERIC has it) and in **loader.conf(5)**:

   ```
   mac_lomac_load="YES"
   ```

6. **UFS.** **mac(4)** / Handbook: per-file labels need **tunefs(8)** `tunefs -l enable` (often single-user) so the file system is `multilabel`. **ZFS** has no `tunefs -l`; test **setfmac(8)** on a throwaway file *before* **setfsmac(8)**. If that fails, abort and leave `security.mac.lomac.enabled=0`.

7. **Network.** Untrusted interfaces default **low** and will demote or block high subjects. Handbook pattern for Biba is `security.mac.*.trust_all_interfaces=1` (RDTUN — **loader.conf(5)** only) plus **ifconfig(8)** `maclabel`. For LOMAC use `security.mac.lomac.trust_all_interfaces=1` and `security.mac.lomac.ptys_equal=1` so SSH/ptys remain usable.

8. **Init credentials.** **mac_lomac(4)** labels `init` **high(low-high)** and `kproc0`/`swapper` **equal**. Root lockout is still possible if **login.conf(5)** pins root to `high(high-high)` and homes are low — keep root **equal** unless the user overrides.

9. **X11 and `/dev` names.** The 2001 PLM used **agp(4)**, **syscons(4)**, `/dev/kmem`, `/tmp/.X11-unix`. Current FreeBSD uses **vt(4)**, **evdev(4)** `/dev/input/event*`, DRM `/dev/dri/card*` (master, treated like old agp → **high**) and `/dev/dri/renderD*` (unprivileged → **equal**), **hid(4)** `hidraw`/`ukbd`/`ums`. `dev-modern.contexts` then `x11-xorg.contexts` are applied first so those names win over `/dev(/.*)?` **equal**. Do not copy agp-only docs verbatim.

## Gotchas (walk before `STAGE_ENFORCE=1`)

These are how MAC/LOMAC deployments lock boxes. The stage script defaults avoid them; do not “helpfully” skip them.

| Hazard | What happens | Mitigation |
| --- | --- | --- |
| Enforce before labels | Processes unlabeled vs files; random EPERM | Stage with `security.mac.lomac.enabled=0`; **setfmac(8)** probe; then **setfsmac(8)**; then `enabled=1` |
| Remote-only enforce | Interfaces default **low**; high SSH session dies or demotes | `security.mac.lomac.trust_all_interfaces=1` in **loader.conf(5)** (RDTUN — not live **sysctl(8)**); keep a console |
| No `ptys_equal` | New ttys unlabeled / high; login weirdness | `security.mac.lomac.ptys_equal=1` |
| Forget **cap_mkdb(1)** | **login.conf(5)** edits have no effect | Always `cap_mkdb /etc/login.conf` |
| Expect class labels in the current session | Labels attach at **login(1)** | New login or reboot after class changes |
| UFS without `multilabel` | **setfmac(8)** fails or one label per FS | **tunefs(8)** `-l enable` in single-user (**mac(4)**) |
| ZFS | No **tunefs(8)** `-l`; some builds reject file labels | Probe **setfmac(8)** on `/tmp`; abort and keep `enabled=0` on failure |
| **setfsmac(8)** without `-x` | Walks NFS/nullfs/other datasets unexpectedly | `-x` and list each local mount (`/`, `/home`, …) |
| `/tmp`, `/var/run`, `/var/log`, `/dev` left **high** | Everyone demotes or cannot write | Official spec already uses **equal** for these — keep it |
| X11 / `/dev` | PLM: `agp`, `kmem`, `.X11-unix` | `dev-modern.contexts`: `card*` **high** (≈ agp), `mem`/`kmem`/`mdctl` **high**. `x11-xorg.contexts`: `renderD*`, `/dev/input/event*`, `kbdmux`, `sysmouse`, `hidraw` **equal**; Xorg logs and `.Xauthority` **equal** |
| **su(1)** high → low home | `_secure_path: unable to stat .login_conf` | Expected Biba/LOMAC; use **equal** root or **setpmac(8)** |
| **Xorg** | Handbook: labeling policies can stop X | Test at console; do not enforce first over SSH from an X box |
| Linuxulator | `/compat/linux` | Overlay `lomac/equal` if Linux binaries must run after demotion |
| Extra MAC modules | Combined labels, impossible proofs | Stay on **mac_lomac(4)** only |
| Per-user overlays | Unmaintainable | Roles = groups; official `/home/.*` **low** is the PLM |
| `STAGE_ENFORCE` on the only SSH session | You can lock yourself out | Root console; `sysctl security.mac.lomac.enabled=0` is the off switch |

## Best-practice procedure

1. **Plan** (Handbook § planning). Classify OS vs user data. LOMAC does not isolate users from reading each other.

2. **Interview** (required). Record answers in `POLICY`. Do not invent a production policy.

3. **install** then **stage** (snapshot + **login.conf(5)** / **loader.conf(5)**). Do not **kldload(8)** yet.

4. **Test window**, root console: `onestart` → `onelabel` → `onechecklabels` → `oneenforce` only if check is clean. New login for class labels. Know `oneuninstall` before enforcing.

5. **Verify:** `onestatus`, **getpmac(8)**, **getfmac(8)**.

6. **Recover:** `oneunenforce`, or `oneuninstall` if the box must behave as before the package.

## Policy interview (what to agree)

| Question | Typical FreeBSD-aligned answers |
| --- | --- |
| Goal | Protect OS integrity from user sessions (**mac_lomac(4)** only). Short proof, few labels. |
| Root | **exempt**: `lomac/equal(equal-equal)` |
| Trusted group | Which **pw(8)** group is `lomac-trusted`? (wheel-like humans). Class `trusted` / `high(low-high)`. Empty group is fine. |
| Sandbox group | Which group is `lomac-sandbox`? Agents/builders. Class `sandbox` / `lomac/10[2]`. |
| Everyone else | `DEFAULT_ROLE=sandbox` (high is opt-in via group) |
| Homes | **Keep official PLM**: `/home/.*` **low**. Overlay only if they insist homes match class (harder to prove) |
| Enforce when | Stage now; **setfsmac(8)** + `enabled=1` only in a test window after § Gotchas |

`POLICY` keys: `TRUSTED_GROUP`, `SANDBOX_GROUP`, `DEFAULT_ROLE`, plus the class/label keys. Overlay rules go in `lomac-overlay.contexts` and are passed to **setfsmac(8)** *before* the official file (first matching spec wins).

## Worked example (host ruach)

Agreed 2026-08-22 as **groups of one**, still the same role model:

- Groups: `lomac-trusted` ∋ `green`; `lomac-sandbox` ∋ `dev`
- Root exempt; official file spec; `enabled=0` until a test window
- Do not treat this overlay as the stock default for other hosts

## Known issues (official docs and mailing lists)

This is the catalog the skill must leave in the **result** README. Walk it before `oneenforce`. Status as of 2026-08. Official sources first; mailing lists / PRs / papers after. None of these are “fixed by this package” unless the last column says so.

### Official — Handbook ch.19 and manuals

Handbook [§19.1](https://docs.freebsd.org/en/books/handbook/mac/#mac-synopsis) and [§19.8 Troubleshooting](https://docs.freebsd.org/en/books/handbook/mac/#mac-troubleshoot). The chapter’s own examples are **demonstration only** and “should *not* be implemented on a production system.”

| Issue | Source | What happens | What this package does |
| --- | --- | --- | --- |
| MAC is an *augmentation*, not a complete security policy | Handbook §19.1 | Relying on LOMAC alone still leaves DAC holes | Integrity proof only; do not stack extra flow modules |
| Examples are not production policy | Handbook §19.1 | Copy-paste Biba/MLS/Nagios labs onto a real box | Interview + official PLM; no handbook `label=` soup |
| Remote MAC | Handbook §19.4 planning | “Implementation of MAC over a remote connection should be done with extreme caution” | `enabled=0` until a test window; console; `oneuninstall` |
| `multilabel` does not stick on UFS `/` | Handbook §19.8 | `tunefs -l enable` appears to work then is lost on reboot | UFS recipe: `fstab` `ro` → single-user `tunefs` → `rw`. **ZFS has no `tunefs -l`** |
| Xorg no longer starts | Handbook §19.8 | `partition` class *or* mislabeled `/dev` / X sockets | `x11-xorg.contexts` + `dev-modern.contexts` first; do not enable `mac_partition(4)` with LOMAC; test at console |
| `_secure_path: unable to stat .login_conf` | Handbook §19.8 | High subject (`root` `biba/high` / LOMAC high) cannot stat a lower-integrity home, even after `su` | Root class is `lomac/equal(equal-equal)` so admin is exempt; still expected for a *high* trusted user `su`’ing into a low home |
| `whoami` prints `0`; `su` says `who are you?` | Handbook §19.8 | Policy `sysctl`’d off or **kldunload(8)**’d while **login.conf(5)** still has `label=`; *or* `master.passwd` inherited a conflicting label | `oneunenforce` then `oneuninstall` (restores **login.conf(5)** + **cap_mkdb(1)**). If passwd is stuck, disable via **sysctl(8)** first |
| Forget **cap_mkdb(1)** | Handbook §19.3.4 | **login.conf(5)** edits have no effect | `update` / `start` always rebuild the db |
| `trust_all_interfaces` is RDTUN | Handbook §19.7.4 (Biba lab); **mac_lomac(4)** / **sysctl(8)** | Live **sysctl(8)** is ignored; interfaces stay **low** and demote SSH | Put `security.mac.lomac.trust_all_interfaces=1` in **loader.conf(5)**; reboot |
| Demotion revokes **mmap(2)** | **mac_lomac(4)** | Shared mappings may vanish when the subject drops (`security.mac.lomac.revocation_enabled`, `security.mac.mmap_revocation`, `…_via_cow`) | Do not enforce until you can recover; watch long-lived high processes that read low files |
| **setfsmac(8)** first match wins | **setfsmac(8)** `-f`: “Only the first entry for each file is applied; all others are disregarded and silently dropped” | Official PLM lists `/dev(/.*)?` **equal** *before* `/dev/mdctl`, `/dev/agp.*`, `/dev/k?mem` **high** — those later lines never apply | Overlays `dev-modern.contexts` then `x11-xorg.contexts` then site overlay are passed **before** the official file |
| MAC Framework experimental / incomplete root containment | **mac(9)** BUGS; **mac_seeotheruids(4)** BUGS | “not all attack channels are currently protected”; do not trust MAC alone against a malicious `root` | Root is *exempt* (equal), not “contained” |
| ZFS vs UFS labels | **mac(4)** / **tunefs(8)**; this host | No `multilabel` flag; labels live in the **system** extattr namespace | `onelabel` **setfmac(8)**-probes `/tmp` and aborts if labels fail; keep `enabled=0` |

### Apocryphal — mailing lists, PRs, original LOMAC paper

These are not Handbook gospel. They still bite.

| Issue | Source | What happens | What this package does |
| --- | --- | --- | --- |
| Original LOMAC “trusted programs”: `pump`, `syslogd`, `sshd` | Fraser, USENIX FREENIX 2001, [Exceptions for Compatibility](https://www.usenix.org/legacy/event/usenix01/freenix01/full_papers/fraser/fraser_html/node9.html) | Linux LOMAC never demotes those binaries so DHCP/syslog/SSH keep working | **mac_lomac(4)** has **no** hard-coded trusted-binary list. FreeBSD equivalent is labels: official `/sbin/dhclient` `high[low]`; `/tmp` `/var/log` `/var/run` **equal**; `ptys_equal=1`; `trust_all_interfaces=1`. Do **not** copy the USENIX exception list into a specfile |
| Aux grade ignored on file extattr | [PR 178667](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=178667) (`[mac] mac_lomac policy ignores aux label when reading/writing file extattr`); still listed on **freebsd-bugs** as of 2024-10 | `lomac/10[2]`-style aux may not apply to extended-attribute I/O | Treat aux as the Handbook login-class / exec trick, not as a complete extattr policy. Do not build a proof that depends on aux covering xattrs |
| `/dev` names from 2001 PLM | Official `lomac-policy.contexts` still has **agp(4)**, `/dev/k?mem`, `/tmp/.X11-unix` (XFree86) | Modern **vt(4)** / **evdev(4)** `/dev/input/event*` / DRM `/dev/dri/card*` + `renderD*` unlabeled or equal-via-`/dev(/.*)?` | `dev-modern.contexts`: `card*` **high** (≈ agp), `mem`/`kmem`/`mdctl`/`zfs` **high**. `x11-xorg.contexts`: `renderD*`, evdev, `kbdmux`, `hidraw`, Xorg logs, `.Xauthority` **equal** |
| “MAC subsystem and ZFS?” | **freebsd-security** (historical thread of that subject); OpenZFS encodes FreeBSD **system** extattrs with a `freebsd:system:` prefix ([commit 5c00613](https://github.com/openzfs/zfs/commit/5c0061345b824eebe7a6578528f873ffcaae1cdd), discussed on **freebsd-testing** / **freebsd-ports-bugs**) | ZFS is not UFS: no `tunefs -l`. Some pools/builds reject file labels. User-namespace xattr (`xattr=sa` vs `dir`) noise on **freebsd-current** (Macklem 2025) is **not** the MAC namespace — do not flip `xattr=` to “fix” LOMAC | Probe **setfmac(8)**; abort on `Invalid argument`. Leave ZFS `xattr` alone unless **setfmac(8)** itself fails |
| Labeled-policy **kldunload(8)** | Early TrustedBSD tutorial traffic (mac_partition / labeled modules returning error 12 / `ENOMEM` while labels still allocated) | Unload fails until processes with labels exit; leftover xattrs are inert only after the module is actually gone | `oneunenforce` (`enabled=0`) **then** `kldunload`. `uninstall` does that. New login after restore |
| Pool checkpoint is a one-shot rewind | **zpool-checkpoint(8)**; Handbook ZFS “Pool Checkpoints”; OpenZFS [#12646](https://github.com/openzfs/zfs/issues/12646) (man pages used to omit that rewind **discards** the checkpoint) | `zpool import --rewind-to-checkpoint` throws away every later txg **and** the checkpoint itself. One checkpoint per pool. Blocks `remove`/`attach`/`detach`/`split`/`reguid`. Scrub does not repair checkpoint-only blocks | Offer checkpoint only with `CHECKPOINT=1`. Prefer `zfs snapshot -r` (filesystems **and** zvols). Never sit on a checkpoint |

### Still true on this host (ruach)

- `/usr/share/security/lomac-policy.contexts` may be missing (empty `share/security` on some installs) — skill ships a copy.
- **getfmac(8)** returns `Invalid argument` until **mac_lomac(4)** is loaded — that is not a ZFS failure.
- Composed under **freebsd-mac**: do not `onesnapshot` here (`MAC_LOMAC_GROK_SKIP_SNAPSHOT=1`).

## See also

**mac(4)**, **mac_lomac(4)**, **mac_biba(4)**, **mac_mls(4)**, **mac_seeotheruids(4)**, **maclabel(7)**, **mac.conf(5)**, **login.conf(5)**, **loader.conf(5)**, **setfsmac(8)**, **setfmac(8)**, **setpmac(8)**, **getfmac(8)**, **getpmac(8)**, **tunefs(8)**, **sysctl(8)**, **kldload(8)**, **ifconfig(8)**, **zpool-checkpoint(8)**, FreeBSD Handbook [ch.19 Mandatory Access Control](https://docs.freebsd.org/en/books/handbook/mac/) (especially [§19.8 Troubleshooting](https://docs.freebsd.org/en/books/handbook/mac/#mac-troubleshoot)), **freebsd-mac-generic** / **freebsd-mac** READMEs (sibling Known issues).
