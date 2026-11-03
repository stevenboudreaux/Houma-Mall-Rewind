# Houma Mall Rewind: the computer packs

This repository's GitHub Pages site serves the computer packs (`w*.desktop.pck`) of
[Houma Mall Rewind](https://stevenboudreaux.github.io/Houma-Mall-Rewind/). A Pages site may hold 1 GB and
the game is more, so the game is split across two sites on the same origin.

Nothing is edited here. `tools/publish_build.sh` in
[stevenboudreaux/Houma-Mall-Rewind](https://github.com/stevenboudreaux/Houma-Mall-Rewind) replaces this
repository's single commit on every publish; the push runs `.github/workflows/pages.yml`, which copies the
computer packs from that repository's `godot-build` branch. `build.txt` names the build.
See `design/godot-build-hosting.md` ("Two sites") there.
