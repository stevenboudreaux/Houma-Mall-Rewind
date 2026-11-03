# godot-build

The current published Godot mall build and its lightmaps, nothing else.

- `play/`: the web export (`tools/export_web.sh`): `index.desktop.pck` and `index.mobile.pck` plus the shared engine files. The Pages workflow on `main` copies these into `prototypes/godot-mall/play/` when it deploys the site.
- `lightmaps/`: `main_night.*` and `main_day.*` to copy into `prototypes/godot-mall/project/` before an export.

This branch is a single commit that each publish replaces with `git push --force`. Do not merge it anywhere.
