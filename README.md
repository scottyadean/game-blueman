# SendHelp

Roblox survival/crafting game. Design doc: [docs/massacareOfblueman.pdf](docs/massacareOfblueman.pdf).

## Layout

- [src/](src/) — Luau source, organized by Roblox service. Rojo syncs this into Studio.
- [place/](place/) — canonical Roblox place file (`SendHelp.rbxlx`, committed). Workspace geometry, lobby rooms, props live here.
- [assets/](assets/) — images, audio, models referenced from code.
- [docs/](docs/) — design docs.
- `build/` — ad-hoc `rojo build` output (gitignored, not authoritative).
- [default.project.json](default.project.json) — Rojo's filesystem-to-DataModel mapping.
- [rokit.toml](rokit.toml) — pinned tool versions (Rojo, Selene, StyLua).

## First-time setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit) (toolchain manager).
2. From the project root: `rokit install` — installs Rojo, Selene, StyLua at the pinned versions.
3. In Roblox Studio: open the Toolbox, search the Plugin Marketplace for **Rojo**, install it.

## Daily workflow

```sh
# Start the live-sync server:
rojo serve
```

Then in Studio:
1. Open [place/SendHelp.rbxlx](place/SendHelp.rbxlx).
2. Click the Rojo plugin → **Connect**.
3. Edits to files under [src/](src/) now sync scripts into Studio in real time.
4. `Ctrl+S` in Studio to persist Workspace changes (rooms, props, geometry) back to the place file.

> First-time bootstrap only (e.g. fresh clone with no `place/` file): `rojo build -o place/SendHelp.rbxlx`.

## Sharing with friends

You can't share an unpublished `.rbxlx` for play — only Studio editing. Two real options:

- **Team Create (co-edit in Studio)**: File → Publish to Roblox (set place to **private**), then File → Game Settings → Security → enable Team Create, then Game Settings → Permissions → invite friends by Roblox username.
- **Private playtest server**: publish as a private place, then Game Settings → Permissions → Play → grant specific users; share the place URL. They join via the Roblox app, no Studio needed.

## Lint and format

```sh
selene src
stylua src
```
