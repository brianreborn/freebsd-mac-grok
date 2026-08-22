# freebsd-mac-grok

Grok **plugin** of three skills plus ports-style **rc.subr(8)** packages for FreeBSD **mac(4)**.

License: **BSD-2-Clause** (`LICENSE`). Not PGP-signed yet. Pin a commit if you need a frozen tree; a signature pass comes later.

Installing the Grok plugin only loads skills (prompts + copies of rc.d scripts). Those scripts change a FreeBSD host only when you (or the agent, with your sudo) run `oneinstall` / `onestage` / `oneenforce`. No install-time hooks, MCP servers, or `curl | bash`. Network: none at plugin install; later, only what you already use (`pkg`, GitHub if you clone).

## Install (Grok)

```sh
grok plugin install brianreborn/freebsd-mac-grok --trust
```

That loads `/freebsd-mac`, `/freebsd-mac-lomac`, and `/freebsd-mac-generic`.

Clone only:

```sh
git clone https://github.com/brianreborn/freebsd-mac-grok.git
# skills are under skills/<name>/ — copy or symlink into ~/.grok/skills/ if you are not using the plugin installer
```

## Skills

| Path | Slash | Role |
| --- | --- | --- |
| `skills/freebsd-mac-lomac/` | `/freebsd-mac-lomac` | **mac_lomac(4)** integrity: roles as **pw(8)** groups, official PLM specfile, Xorg/`/dev` overlays, PREINSTALL uninstall |
| `skills/freebsd-mac-generic/` | `/freebsd-mac-generic` | Orthogonal modules (**mac_seeotheruids(4)**, …). No ZFS. |
| `skills/freebsd-mac/` | `/freebsd-mac` | Umbrella: **zfs snapshot -r** (filesystems and zvols) and optional **zpool-checkpoint(8)** before *and* after staging. No **bectl(8)**. |

Each skill ships a README with **Known issues** (Handbook ch.19 and mailing lists/PRs) and section 4/5/7/8 manuals.

## pqac(7)

```sh
mandoc -T pdf skills/freebsd-mac/man/man7/pqac.7 > skills/freebsd-mac/references/pqac.pdf
# or:
make -C skills/freebsd-mac/references
```

Rendered PDF: `skills/freebsd-mac/references/pqac.pdf`.

## Host install (FreeBSD)

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

## Signatures

Unsigned on purpose. A later pass will PGP-sign tags and/or release artifacts. Until then, treat `main` as moving and pin:

```sh
git ls-remote https://github.com/brianreborn/freebsd-mac-grok.git HEAD
```
