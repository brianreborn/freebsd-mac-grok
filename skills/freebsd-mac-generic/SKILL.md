---
name: freebsd-mac-generic
description: >
  Configure orthogonal FreeBSD MAC modules other than LOMAC (mac_seeotheruids(4),
  mac_ifoff(4), mac_portacl(4), mac_bsdextended(4), …) as login-group-friendly
  loader.conf(5)/sysctl(8) policy, emitting an rc.subr(8) package with stage,
  update, and uninstall. Does not take ZFS snapshots (freebsd-mac owns
  before/after snaps). Use when the user wants seeotheruids, ugidfw, portacl,
  ifoff, MAC process hiding, or runs /freebsd-mac-generic.
---

# freebsd-mac-generic

Read `README.md` and `references/catalog.md` first. This skill is **not** **mac_lomac(4)** (use **freebsd-mac-lomac**). It does **not** snapshot ZFS (use **freebsd-mac**).

`${SKILL_DIR}` = this skill directory (plugin `skills/freebsd-mac-generic` or `~/.grok/skills/freebsd-mac-generic`).

## Output

Result dir default `~/freebsd-mac-generic/`:

1. Copy `README.md` → `$RESULT/README` (**keep** § Known issues; do not strip Handbook / list caveats)
2. Copy `references/catalog.md`
3. Copy `scripts/mac_generic_grok` (0755) and `man/` (sections 4, 5, 8)
4. Write `$RESULT/POLICIES` (one module name per line, no `mac_` prefix: `seeotheruids`)
5. Write `$RESULT/POLICY` knobs (`SEEOTHERUIDS_EXEMPT_GID=0`, …)

Then `sudo $RESULT/mac_generic_grok oneinstall` && `onestage`. No kldload until `onestart` or reboot.

## Interview

1. Which catalog modules? Default: **mac_seeotheruids(4)** only (orthogonal to LOMAC, easy to prove: “you cannot see other UIDs except exempt GID”).
2. Exempt GID for seeotheruids (default `0` = `wheel`).
3. Never add **mac_biba(4)** / **mac_mls(4)** unless they insist.
4. **mac_ifoff(4)**: warn it can kill SSH (`other_enabled=0` by default in our stanza). Walk README § Known issues (Handbook ifoff, seeotheruids vs root, single `specificgid`, ugidfw reload, partition unload).
5. **mac_partition(4)** needs labels — prefer seeotheruids.

## Apply

`oneinstall` → `onestage` (PREINSTALL then marked **loader.conf(5)** blocks) → `oneupdate` later → `onestart` loads klds → `oneuninstall` restores PREINSTALL.

If invoked from **freebsd-mac**, do not mention ZFS; parent already snapped.
