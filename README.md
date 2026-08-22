# freebsd-mac-grok

Grok skills and ports-style **rc.subr(8)** packages for FreeBSD **mac(4)**.

Live copies on a workstation also live under `~/.grok/skills/` with the same directory names. This repository is the durable tree.

| Directory | Skill / rc.d | Role |
| --- | --- | --- |
| `freebsd-mac-lomac/` | `mac_lomac_grok` | **mac_lomac(4)** integrity: roles as **pw(8)** groups, official PLM specfile, Xorg/`/dev` overlays, PREINSTALL uninstall |
| `freebsd-mac-generic/` | `mac_generic_grok` | Orthogonal modules (**mac_seeotheruids(4)**, …). No ZFS. |
| `freebsd-mac/` | `mac_grok` | Umbrella: **zfs snapshot -r** (filesystems and zvols) and optional **zpool-checkpoint(8)** before *and* after staging. No **bectl(8)**. |

Each skill ships a README with **Known issues** (Handbook ch.19 and mailing lists/PRs) and section 4/5/7/8 manuals.

## pqac(7)

Short mdoc paper on quantum-adversary-stable mediation (exoteric and esoteric):

```sh
mandoc -T pdf freebsd-mac/man/man7/pqac.7 > freebsd-mac/references/pqac.pdf
# or:
make -C freebsd-mac/references
```

A rendered PDF is kept at `freebsd-mac/references/pqac.pdf`.

## Install (on FreeBSD)

The skills interview, then emit a result directory. From a result tree:

```sh
sudo ./mac_grok oneinstall
sudo service mac_grok onesnapshot    # extra-safe, before any stage
sudo service mac_grok onestage
sudo service mac_grok onesnapshot_after
# labels / enforce: service mac_lomac_grok onelabel && oneenforce
# always: test* first; console; README Known issues
```

Do not `kldload` **mac_lomac(4)** or set `security.mac.lomac.enabled=1` until a test window. `oneuninstall` restores pre-install *behavior* from `PREINSTALL/`.
