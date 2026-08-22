# REMNANT

Record of where this work sits **on disk and on GitHub**, and what is still required to **install the software the skills represent**. Written 2026-08-22 on host **ruach** (`FreeBSD 15.1-RELEASE` amd64). Review this file, then take snapshots, then resume Headroom. Do not treat this as a substitute for the skill READMEs or **pqac(7)**.

Unsigned. Light-ware license (`LICENSE`, copied from `~/japanglify/LICENSE`). Pin commits; do not treat `main` as frozen.

| Repo | Plugin install | HEAD when this was written |
| --- | --- | --- |
| https://github.com/brianreborn/freebsd-mac-grok | `grok plugin install brianreborn/freebsd-mac-grok --trust` | see `git ls-remote … HEAD` |
| https://github.com/brianreborn/max-headroom-grok | `grok plugin install brianreborn/max-headroom-grok --trust` | see `git ls-remote … HEAD` |

Live Grok copies (not git): `~/.grok/skills/freebsd-mac{,-lomac,-generic}/`, `~/.grok/skills/max-headroom/`. Git trees: `~/freebsd-mac-grok/`, `~/max-headroom-grok/`. Edits in one place are not the other.

---

## General state (done)

Skills **exist** and are **published as Grok plugins**. They have not **applied** their payloads on ruach except Headroom’s git checkout and some OS packages.

**Written**

- **freebsd-mac-lomac** — `mac_lomac_grok` rc.d, official PLM + `dev-modern`/`x11-xorg` overlays, PREINSTALL uninstall, man 4/5/7/8, Known issues, test*
- **freebsd-mac-generic** — orthogonal MAC modules, man 4/5/8, catalog
- **freebsd-mac** — umbrella, ZFS `snapshot -r` (fs + zvol) before and after, optional checkpoint, **no bectl**, **pqac(7)** + PDF
- **max-headroom** — install Headroom, `max-headroom.script` protocol
- **pqac(7)** — CS note (exoteric mediation / esoteric observation / praxis from packaging MAC on GENERIC)
- **TODO.md** (this repo) — MAC host checklist

**Not written as original work (do not republish):** bundled Grok skills (`docx`, `pptx`, `help`, `create-skill`, …).

**Policy agreed for ruach (reconfirm at interview, not applied):** protect OS integrity; root `lomac/equal(equal-equal)`; `lomac-trusted` ∋ `green`; `lomac-sandbox` ∋ `dev`; homes follow official PLM (`/home/.*` low); configure files now, **do not** `kldload` / `enabled=1` until a test window.

**xAI marketplace:** shape is catalog-capable (plugin.json, LICENSE, public SHA). No PR yet. PGP later.

---

## Host facts (ruach)

| Item | State |
| --- | --- |
| Users | `root`; `green` (wheel, desktop); `dev` (ksh93) |
| Kernel | GENERIC, `options MAC`; `/boot/kernel/mac_lomac.ko` present (not loaded) |
| Root pool | `zroot` — datasets include `zroot/ROOT/default` → `/`, `zroot/home/dev` → `/home/dev`, `zroot/home/green`, `zroot/tmp`, `zroot/usr`, `zroot/var`, … |
| Pool checkpoint | **none** (`zpool get checkpoint zroot` → `-`) |
| Package ZFS snaps | **none** from `mac_grok` / `mac_lomac_grok` |
| `/usr/local/etc/rc.d/mac_*` | **absent** |
| Result dirs `~/freebsd-mac*` | **absent** |
| Pre-skill leftovers | `~/configure-mac-lomac.sh`, `~/lomac.contexts` (superseded; do not run) |
| Python | `python3.12` only (`python3` not on PATH) |
| `uv` | **missing** (no FreeBSD binary last check) |
| Rust | `~/.cargo/bin/rustc` 1.98.0 (not always on default PATH) |
| Headroom checkout | `~/projects/headroom` @ **v0.36.4** |
| `headroom` CLI | **missing** |
| `max-headroom.script` | **missing** |
| `~/max-headroom.sh` | written; **pkg** extras already installed (`cmake-core`, `ninja`, `pkgconf`, `py312-scipy`, `py312-scikit-learn`, `py312-pytorch`, `py312-onnxruntime`) |
| `pip install --user headroom-ai==0.36.4` | **failed wheel** for native `headroom-py` (`ort` crate, non-exhaustive `ORT_DYLIB_PATH` match on FreeBSD); process may still be compiling other sdists (e.g. litellm) |

---

## Install remnant — Headroom (`/max-headroom`)

**Do this after review + snapshots.** Skill: `~/.grok/skills/max-headroom` or plugin `brianreborn/max-headroom-grok`.

Checkout is already at the desired tag. Do **not** wipe `~/projects/headroom`. Goal: a working `headroom` binary + `max-headroom.script` + optional proxy `:8787` + Grok wrap/MCP.

1. **Stop or inspect** any leftover `python3.12 -m pip install --user headroom-ai==0.36.4`. The `headroom-ai` wheel **already failed** (`ort` / maturin on FreeBSD). Letting it grind litellm does not fix the native crate.
2. **PATH:** `export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:$PATH"`. There is no `python3`; use `python3.12`.
3. **Do not wait on `uv`.** No FreeBSD `uv` download last try; pip+rustup is the path.
4. **CLI without `[all]` first** (avoid compiling sklearn/onnx again; those are already pkg). Options, in order:
   - Install from the **checkout** with maturin/cargo after addressing the `ort` `E0004` on FreeBSD (env `ORT_DYLIB_PATH` / `ort` version / skip ONNX extra).
   - `python3.12 -m pip install --user --no-build-isolation` from `~/projects/headroom` if the repo’s `headroom-py` can be built with `ORT_DYLIB_PATH` set to the system `onnxruntime` dylib (`py312-onnxruntime`).
   - If `[all]` extras are required later, prefer **system** scipy/sklearn/pytorch rather than pip source builds (those were killed earlier).
5. Verify: `command -v headroom`, `headroom --version` (expect 0.36.4), `headroom doctor`. Record the **absolute** path.
6. Write **`max-headroom.script`** from `skills/max-headroom/references/protocol-template.md` to **all** of:
   - `~/projects/headroom/max-headroom.script`
   - `~/.grok/skills/max-headroom/max-headroom.script`
   - `~/max-headroom.script` if cwd is elsewhere
7. If `http://127.0.0.1:8787/health` is down: `headroom proxy --port 8787` (background). Profile `coding`.
8. `headroom mcp install` (absolute binary) or hand-edit `~/.grok/config.toml`.
9. `headroom wrap grok-build` or `headroom wrap grok` (`--no-proxy` if this session already started one). Restart Grok for wrap+MCP on inference.
10. Copy any skill edits into `~/max-headroom-grok` and push if you want them public.

**Known install trap:** Headroom has **no** `x86_64-unknown-freebsd` wheel; sdist builds `headroom-py` via maturin. `ort 2.0.0-rc.12` failed to compile here. That is the blocker, not the skill text.

---

## Install remnant — FreeBSD MAC (`/freebsd-mac`)

**Parked until Headroom is engaged, unless you choose otherwise.** Nothing from these skills is on the box. `TODO.md` is the short checklist; this is the order and the traps.

Do **not** `oneenforce` until a **root console** and clean `onechecklabels`. Walk skill README **Gotchas**, **Known issues**, and **pqac(7)** PRAXIS first.

### 0. Snapshots (you asked to take these after reviewing this file)

This is **not** the skill’s `onesnapshot` until the package is installed. Extra-safe **before** any MAC or further Headroom compile:

```sh
# Review REMNANT.md / TODO.md first, then:
zfs list -t filesystem,volume -r zroot
# Recursive snap of the pool (filesystems and zvols):
sudo zfs snapshot -r zroot@pre-headroom-mac-$(date -u +%Y%m%dT%H%M%SZ)
# Optional, one per pool, rewind discards later txgs:
# sudo zpool checkpoint zroot
```

Record snap names. Skill `onesnapshot` later is a **second**, package-named snap (`mac_grok-pre-…`). Do not confuse them. **No bectl.**

### 1. Emit and install the suite

```sh
# /freebsd-mac  — interview (reconfirm ruach policy), write ~/freebsd-mac/
sudo ~/freebsd-mac/mac_grok oneinstall
# children skip ZFS when umbrella runs (MAC_LOMAC_GROK_SKIP_SNAPSHOT=1)
```

Expect `/usr/local/etc/rc.d/mac_grok`, `mac_lomac_grok`, `mac_generic_grok` and manpages. `*_enable` defaults **NO** → use `service … one*`.

### 2. Package snapshots, then stage (still `enabled=0`)

```sh
sudo service mac_grok testsnapshot
sudo service mac_grok onesnapshot          # zfs snapshot -r ; CHECKPOINT=1 only if you accept rewind
sudo service mac_grok teststage
sudo service mac_grok onestage             # PREINSTALL once, never overwrite
sudo service mac_grok onesnapshot_after
```

PREINSTALL = behavioral restore source (`loader.conf`, `login.conf`+db, classes). Not a forensic wipe.

### 3. Load module, label, check — still not enforce

```sh
sudo service mac_grok onestart             # kldload; lomac enabled=0
sudo service mac_lomac_grok testlabel
sudo service mac_lomac_grok onelabel       # setfmac probe on /tmp, then setfsmac -x
sudo service mac_lomac_grok onechecklabels
```

If **setfmac** on `/tmp` is `EINVAL` after kldload, **abort**; keep `enabled=0`. ZFS has no `tunefs -l`. Overlays **before** official PLM (**setfsmac(8)** first-match).

### 4. Enforce only in a test window

```sh
# console, not the only SSH session
sudo service mac_lomac_grok oneenforce     # security.mac.lomac.enabled=1
# off switch:
sudo sysctl security.mac.lomac.enabled=0
```

`trust_all_interfaces` is **RDTUN** (`loader.conf`), not live sysctl. `ptys_equal=1`. New login for class labels. **cap_mkdb** after `login.conf` edits.

### 5. Recover

```sh
sudo service mac_grok oneuninstall         # children restore PREINSTALL; snaps kept
# if that is not enough:
# zfs rollback -r zroot@<pre-snap>
# checkpoint rewind last, destructive, one-shot
```

`uninstall` ≠ wipe (xattrs remain) ≠ pool rewind.

Generic default with LOMAC: **mac_seeotheruids(4)** only, exempt GID 0 (`wheel`). Do not enable **mac_ifoff(4)** blindly (`other_enabled=0` kills the wire). Do not stack Biba/MLS.

---

## After public record, proposed sequence

1. **Review** this file and `TODO.md` (this step).
2. **System / filesystem snapshots** (commands in §0) — operator.
3. **Resume Headroom** (§ Headroom remnant) until `headroom --version` and `max-headroom.script` exist.
4. MAC suite remains parked on the checklist unless you unpark it.

Do not `oneenforce`. Do not PGP-sign until you ask. Do not PR the xAI marketplace until a SHA is frozen (after PGP if you want that first).
