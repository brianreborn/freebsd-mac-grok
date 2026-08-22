# TODO — freebsd-mac-grok

Writing and GitHub publish are done (`main`, plugin layout, **pqac(7)**).
Nothing from these skills is installed or enforced on the host.

Pin while unsigned: `git ls-remote https://github.com/brianreborn/freebsd-mac-grok.git HEAD`

## On the host (MAC)

Do **not** `oneenforce` until a root console and a clean `onechecklabels`.

- [ ] `/freebsd-mac` (or `/freebsd-mac-lomac` alone) — emit result dirs, copy from skills
- [ ] `testsnapshot` then `onesnapshot` (`zfs snapshot -r`, filesystems + zvols)
- [ ] `teststage` then `onestage` (PREINSTALL + login.conf / loader.conf / groups)
- [ ] `onesnapshot_after`
- [ ] `onestart` (`kldload`, `security.mac.lomac.enabled=0`)
- [ ] `testlabel` then `onelabel` (setfmac probe + setfsmac)
- [ ] `onechecklabels`
- [ ] Walk README **Gotchas** + **Known issues** + **pqac(7)** PRAXIS
- [ ] `oneenforce` only in a test window; `sysctl security.mac.lomac.enabled=0` is the off switch
- [ ] Confirm `oneuninstall` is understood (behavior restore, not wipe, not pool rewind)

Agreed ruach policy (reconfirm at interview): root `equal(equal-equal)`; `lomac-trusted` ∋ `green`; `lomac-sandbox` ∋ `dev`; official PLM; files staged, module off until the window.

## Later (artifact)

- [x] BSD-2-Clause `LICENSE` (catalog requirement)
- [ ] PGP signature pass (tags / release artifacts). Not now. README already says unsigned.
- [x] `max-headroom` is its own plugin: https://github.com/brianreborn/max-headroom-grok
- [ ] Optional: xAI marketplace PR (fork index, pin 40-char SHA, not `main`)

## Hygiene

Live Grok copies: `~/.grok/skills/freebsd-mac{,-lomac,-generic}/`
Git tree: `~/freebsd-mac-grok/skills/…`

Edits in one place are not the other. Copy into the git tree and push before calling it saved.

Leftover pre-skill files (do not confuse with the package):

- `~/configure-mac-lomac.sh`
- `~/lomac.contexts`

## Stack (paused here)

MAC deploy is parked on this list.

Popped: **Headroom** (`/max-headroom`) — checkout `~/projects/headroom` @ v0.36.4; `~/max-headroom.sh` for remaining pkgs; no `headroom` CLI; no `max-headroom.script`.
