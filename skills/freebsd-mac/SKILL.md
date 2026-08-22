---
name: freebsd-mac
description: >
  Orchestrate FreeBSD MAC policy on a host: mac_lomac(4) plus orthogonal
  modules (seeotheruids, …). Take zfs(8) recursive snapshots (filesystems
  and zvols) and optional zpool-checkpoint(8) BEFORE any policy change
  and AFTER the suite is staged. No bectl(8). Delegates to
  freebsd-mac-lomac and freebsd-mac-generic; children skip their own
  snaps. Use when the user wants a full MAC setup, /freebsd-mac, or
  “snapshot then LOMAC and seeotheruids”.
---

# freebsd-mac

Read `README.md`. This is the **suite**. Snapshot/checkpoint live **only** here (before and after). Do not let children `onesnapshot`.

`${SKILL_DIR}` = this skill directory (plugin `skills/freebsd-mac` or `~/.grok/skills/freebsd-mac`).
Also load **freebsd-mac-lomac** and **freebsd-mac-generic** skills when those pieces run.

## Output

Result `~/freebsd-mac/`:

1. Copy `scripts/mac_grok` (0755), this `README.md` (**keep** § Known issues; it points at the child catalogs), and `man/` (sections 4, 7, 8, including `pqac.7`). Optional: `mandoc -T pdf man/man7/pqac.7 > references/pqac.pdf`.
2. Write `SUITE` (`WITH_LOMAC=YES`, `WITH_GENERIC=YES`, policy list).
3. If LOMAC: run **freebsd-mac-lomac** into `$RESULT` (or `~/freebsd-mac-lomac` and copy `mac_lomac_grok` + contexts into `$RESULT`). Set `MAC_LOMAC_GROK_SKIP_SNAPSHOT=1`.
4. If generic: run **freebsd-mac-generic** into `$RESULT` (`POLICIES`, `mac_generic_grok`).
5. `sudo $RESULT/mac_grok oneinstall`.

## Order (strict)

1. Interview: LOMAC? which generic modules? exempt GID? roles/groups (lomac skill).
2. **Offer** `onesnapshot` (**zfs snapshot -r** on the root pool — filesystems and zvols; `CHECKPOINT=1` only if they accept pool rewind). Do this **before** any `onestage`.
3. `onestage` — children stage with skip-snapshot.
4. **Offer** `onesnapshot_after` so there is a known-good post-config recursive snap.
5. `onestart` / lomac `onelabel` / `oneenforce` only if they ask; walk LOMAC gotchas **and** all three README Known issues sections (Handbook §19.8, lists/PRs, checkpoint rewind) first.
6. Recover: `oneuninstall` (children restore configs) then optional `zfs rollback -r pool@mac_grok-pre-…`.

Never snapshot inside LOMAC/generic when this skill is the caller (`MAC_LOMAC_GROK_SKIP_SNAPSHOT=1`, `MAC_GROK_SKIP_SNAPSHOT` only if they refuse all ZFS).
