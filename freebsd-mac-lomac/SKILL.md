---
name: freebsd-mac-lomac
description: >
  Collaboratively design a FreeBSD mac_lomac(4) integrity policy for groups of
  users (login.conf classes bound to pw groups), then write a standalone
  result directory using base tools and the official
  /usr/share/security/lomac-policy.contexts via setfsmac(8). Prefer LOMAC's
  simple high/low/equal proof over extra MAC modules. Stage with
  security.mac.lomac.enabled=0; do not kldload or enforce until a test
  window. Use when the user wants LOMAC, MAC labels, setfsmac, login-class
  roles, TrustedBSD policy, or runs /freebsd-mac-lomac.
---

# freebsd-mac-lomac

Human usage, defaults, and **mac_lomac(4)**-style references: read `README.md` in this skill directory first. Follow it. File labels still go through **setfsmac(8)**. The *package* the skill emits is an **rc.subr(8)** script (`mac_lomac_grok`) with extra commands — including **uninstall** that restores pre-install behavior from a one-time snapshot.

`${SKILL_DIR}` = this skill (`~/.grok/skills/freebsd-mac-lomac`).

## Output: one result directory

Create **one** directory (not scattered `$HOME` files). Default `~/freebsd-mac-lomac`; if it exists, use it. Copy:

1. `README.md` → `$RESULT/README` (append an “Agreed policy” section with the interview). **Keep** the skill README’s § Known issues (official Handbook / manuals **and** mailing lists / PRs). Do not strip it. Before `oneenforce`, walk Gotchas **and** Known issues.
2. Official spec → `$RESULT/lomac-policy.contexts`:
   - Prefer `/usr/share/security/lomac-policy.contexts` (**setfsmac(8)** `FILES`).
   - Else `${SKILL_DIR}/references/lomac-policy.contexts`.
3. `${SKILL_DIR}/scripts/mac_lomac_grok` → `$RESULT/mac_lomac_grok` (mode 0755). Copy `mac_lomac_grok.conf` and keep `scripts/stage-mac-lomac.sh` as a thin `one*` wrapper if present. Copy `${SKILL_DIR}/references/x11-xorg.contexts` and `dev-modern.contexts` into `$RESULT` (always). Copy `${SKILL_DIR}/man/` into `$RESULT/man/` (sections 4, 5, 7, 8).
4. Write `$RESULT/POLICY` (`KEY=value`) and optional `$RESULT/lomac-overlay.contexts`.

Then: `sudo $RESULT/mac_lomac_grok oneinstall`. If this skill is **standalone**, **offer** `onesnapshot` then `onestage`. If invoked from **freebsd-mac**, skip ZFS (`MAC_LOMAC_GROK_SKIP_SNAPSHOT=1`); the umbrella snapshots before and after the whole suite.

Never enforce in this phase. Tell them **uninstall** (`service mac_lomac_grok oneuninstall`) restores pre-install *behavior* from `/var/db/mac_lomac_grok/PREINSTALL` (module unloaded, configs and login classes restored). MAC xattrs may remain but are inert without **mac_lomac(4)**.

## Detect

Must be FreeBSD (`uname -s`). Confirm `sysctl security.mac.version`, `/boot/kernel/mac_lomac.ko`, **getfmac(8)**/**setfsmac(8)**. If not FreeBSD, stop.

Do **not** `kldload` **mac_lomac(4)** and do **not** set `security.mac.lomac.enabled=1` in this phase.

## Interview (required)

Ask the questions in `README.md` § Policy interview. Roles are **groups**, not individual accounts. Record group names; members share one **login.conf(5)** class.

Do not assume ruach’s overlay unless this host is ruach **and** the user reconfirms.

Map answers into `POLICY`:

```
TRUSTED_CLASS=trusted
SANDBOX_CLASS=sandbox
TRUSTED_GROUP=lomac-trusted
SANDBOX_GROUP=lomac-sandbox
DEFAULT_ROLE=sandbox
ROOT_LABEL=lomac/equal(equal-equal)
TRUSTED_LABEL=lomac/high(low-high)
SANDBOX_LABEL=lomac/10[2]
```

Stock FreeBSD: official contexts only (empty overlay), `SANDBOX_LABEL=lomac/10[2]`, `DEFAULT_ROLE=sandbox`, no home overlay. That is the LOMAC PLM: OS high, user trees low, subjects demote — easy to *configure* and easy to *prove*.

If they insist homes match class, overlay **only** those regexes in `lomac-overlay.contexts` (same **setfsmac(8)** syntax). Do not invent a format, compartments, or extra modules (**mac_biba(4)**, **mac_mls(4)**, **mac_seeotheruids(4)**).

Before `oneenforce`, walk `README.md` § Gotchas (interfaces, ptys, UFS/ZFS, `/tmp`, new login, root console) **and** § Known issues (Handbook §19.8, **setfsmac(8)** first-match, mmap revocation, USENIX trusted-binaries vs FreeBSD labels, PR 178667, `/dev` PLM vs DRM/evdev). Confirm they know `oneuninstall`.

## Apply

Root, via **service(8)** `one*` (enable defaults to NO):

1. `oneinstall` — copy into `/usr/local`
2. **Offer `onesnapshot`** — `zfs snapshot -r` (filesystems and zvols); checkpoint only if they opt in
3. `onestage` — write PREINSTALL (never overwrite), then **login.conf(5)** / **loader.conf(5)** / groups
4. `oneupdate` / `onereload` — later: **cap_mkdb(1)**, group→class, POLICY labels, contexts (not **setfsmac(8)**)
5. `onestart` — **kldload(8)**, `enabled=0`; also syncs login classes
6. `onelabel` — **setfmac(8)** probe then **setfsmac(8)**
7. `onechecklabels` — sentinels
8. `oneenforce` — only if they ask
9. `oneuninstall` — restore PREINSTALL; unload module; remove `/usr/local` files; **keep** the snapshot

UFS: if `mount` shows ufs without `multilabel`, tell them **tunefs(8)** `-l enable` (single-user) per **mac(4)**.

Privilege: one sudo. Never ask “continue?”

## After

Point at `$RESULT`, install/stage/`oneupdate` for later **login.conf(5)**/group changes, and `oneuninstall` as the no-snapshot recovery. Leave `$RESULT/README` § Known issues intact so the installed package documents Handbook and mailing-list issues.
