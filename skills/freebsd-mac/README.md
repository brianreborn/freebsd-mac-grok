# freebsd-mac

Suite installer for FreeBSD **mac(4)**: **mac_lomac(4)** (integrity) plus orthogonal modules (**mac_seeotheruids(4)**, …). **zfs(8)** recursive snapshots (filesystems **and** zvols) and optional **zpool-checkpoint(8)** happen only here — once **before** any policy mutation and once **after** staging. No **bectl(8)**.

Child skills:

| Skill | rc.d | Role |
| --- | --- | --- |
| **freebsd-mac-lomac** | `mac_lomac_grok` | LOMAC labels, login classes, Xorg overlay |
| **freebsd-mac-generic** | `mac_generic_grok` | seeotheruids, ifoff, portacl, ugidfw, … |
| **freebsd-mac** (this) | `mac_grok` | Snapshots + orchestration |

## Invoke

`/freebsd-mac` — “full MAC setup”, “LOMAC and seeotheruids”, “snapshot then apply MAC”.

## Order

```sh
sudo ~/freebsd-mac/mac_grok oneinstall
sudo service mac_grok onesnapshot          # BEFORE — zfs snapshot -r (fs + zvol)
# CHECKPOINT=1 … onesnapshot               # optional zpool-checkpoint(8)
sudo service mac_grok onestage             # children; they skip ZFS
sudo service mac_grok onesnapshot_after    # AFTER — second recursive snap
sudo service mac_grok onestart
# lomac file labels / enforce: service mac_lomac_grok onelabel && oneenforce
sudo service mac_grok oneupdate            # later: both children
sudo service mac_grok oneuninstall         # config restore; ZFS snaps kept
```

| Command | Effect |
| --- | --- |
| `snapshot` | `mac_grok-pre-<utc>` **zfs snapshot -r** (all filesystems and volumes on the root pool); **zpool-checkpoint(8)** only if opted in |
| `snapshot_after` | `mac_grok-post-<utc>` same `-r` snap (no second checkpoint) |
| `stage` | `MAC_LOMAC_GROK_SKIP_SNAPSHOT=1` child `onestage` |
| `update` | child `oneupdate` (**login.conf(5)**, POLICIES, **cap_mkdb(1)**) |
| `uninstall` | child uninstalls (PREINSTALL restore) then removes `mac_grok`; **does not** destroy ZFS snaps |
| `test*` | Dry-run of the matching command. Diffs/`WOULD` only; run immediately before the real target. |

Rollback: `zfs rollback -r <pool>@mac_grok-pre-…`. Names: `/var/db/mac_grok/zfs.snaps`. Pool-wide rewind only if a checkpoint was taken (**zpool-checkpoint(8)**; discards later txgs).

## Why two snapshots

- **pre**: pool datasets (filesystems + zvols) as they were.
- **post**: known-good after stage, before `oneenforce`. If enforce goes badly, `uninstall` first; if that is not enough, `zfs rollback -r` to **pre**.

## Known issues (official docs and mailing lists)

The suite README must keep this section. Child catalogs (do not duplicate here — read them before `oneenforce`):

- **freebsd-mac-lomac** README § Known issues — Handbook §19.8 (`multilabel`, Xorg, `_secure_path`, `whoami`/`root`), **setfsmac(8)** first-match, **mac_lomac(4)** mmap revocation, USENIX LOMAC `pump`/`syslogd`/`sshd` vs FreeBSD labels, PR 178667 aux/extattr, ZFS system xattrs, `/dev` PLM vs DRM/evdev.
- **freebsd-mac-generic** README § Known issues — **mac_ifoff(4)** dropping the wire, seeotheruids vs root (kern/72263, bin/79714, `suser_privileged`), single `specificgid`, ugidfw new-user reload, partition unload `ENOMEM`.

### Official — this suite’s own hazards

| Issue | Source | What happens | What this package does |
| --- | --- | --- | --- |
| Handbook examples are not production | Handbook [§19.1](https://docs.freebsd.org/en/books/handbook/mac/#mac-synopsis) | Nagios/Biba lab `label=` soup | Children interview; official LOMAC PLM; seeotheruids-only default |
| Remote MAC | Handbook [§19.4](https://docs.freebsd.org/en/books/handbook/mac/#mac-planning) | “done with extreme caution” | Snapshots **before** any `onestage`; `enabled=0`; console |
| MAC is experimental / incomplete vs malicious root | **mac(9)** BUGS | Framework is an augmentation | Do not advertise “root contained” |
| Stacking Biba/MLS with LOMAC | Handbook planning; **mac_lomac(4)** | Combined labels, unprovable policy | Generic catalog refuses **mac_biba(4)** / **mac_mls(4)** unless insisted |
| UFS `multilabel` not sticky on `/` | Handbook [§19.8](https://docs.freebsd.org/en/books/handbook/mac/#mac-troubleshoot) | Flag lost across reboot | LOMAC child: `fstab` `ro` dance. This host is ZFS — no `tunefs -l` |
| Pool checkpoint rewind is destructive | **zpool-checkpoint(8)**; Handbook [ZFS Pool Checkpoints](https://docs.freebsd.org/en/books/handbook/zfs/) | Export/import `--rewind-to-checkpoint` discards **every** later txg (new snapshots, property changes, added vdevs). One checkpoint per pool. Blocks `remove`/`attach`/`detach`/`split`/`reguid`. Long-lived checkpoint can fill the pool. Scrub does not repair checkpoint-only data | Opt-in `CHECKPOINT=1` only. Default is `zfs snapshot -r` (filesystems **and** zvols). No **bectl(8)** |
| Checkpoint discarded on rewind | OpenZFS [#12646](https://github.com/openzfs/zfs/issues/12646) (man pages historically implied snapshot-like reuse) | You cannot rewind twice | Prefer the recursive snapshot; treat checkpoint as a seatbelt for one mistake |
| `uninstall` ≠ pool rewind | this package | PREINSTALL restores **config behavior** (modules unloaded, **login.conf(5)** / **loader.conf(5)** copied back). MAC xattrs and ZFS snaps remain | `oneuninstall` first; `zfs rollback -r pool@mac_grok-pre-…` only if that is not enough. Checkpoint rewind last |

### Apocryphal — lists

| Issue | Source | What happens | What this package does |
| --- | --- | --- | --- |
| ZFS vs MAC labels | **freebsd-security** “MAC subsystem and ZFS?”; OpenZFS `freebsd:system:` extattr prefix | No UFS `multilabel`; **setfmac(8)** may return `Invalid argument` until the module is loaded *or* if the pool cannot store system xattrs | LOMAC `onelabel` probes `/tmp`. Do not flip `zfs set xattr=` (user-namespace `sa`/`dir` debates on **freebsd-current** are a different API) |
| `/dev` names vs 2001 PLM | official `lomac-policy.contexts` still lists **agp(4)** | DRM/evdev unlabeled | LOMAC overlays `dev-modern.contexts` **before** the official file (**setfsmac(8)** first-match) |

Walk the child Known issues **and** LOMAC Gotchas before `service mac_lomac_grok oneenforce`.

## See also

**mac(4)**, **mac_lomac(4)**, **mac_seeotheruids(4)**, **zfs(8)**, **zpool-checkpoint(8)**, **rc.subr(8)**, **pqac(7)** (exoteric/esoteric note on quantum-adversary-stable mediation; render with `mandoc -T pdf`), FreeBSD Handbook [ch.19](https://docs.freebsd.org/en/books/handbook/mac/) ([§19.8](https://docs.freebsd.org/en/books/handbook/mac/#mac-troubleshoot)), **freebsd-mac-lomac**, **freebsd-mac-generic**.

---
Copyright © 2026 Brian Fundakowski Feldman. Light-ware License — see the repository root [LICENSE](https://github.com/brianreborn/freebsd-mac-grok/blob/main/LICENSE) and [NOTICE.md](https://github.com/brianreborn/freebsd-mac-grok/blob/main/NOTICE.md).

