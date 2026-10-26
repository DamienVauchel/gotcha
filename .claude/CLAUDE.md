# gotcha — working on the plugin

## README and wiki are living docs

`README.md` and `wiki/` are gotcha's own human docs. They must describe what the
plugin ships **in the same PR** that changes it:

| You change | Update |
|---|---|
| a skill (`skills/`) | `README.md` commands table, `wiki/Commands.md` and the page that explains its procedure |
| an agent (`agents/`) | `wiki/Agents.md` |
| a hook (`hooks/`) | `wiki/Hooks.md`, and `wiki/How-It-Works.md` if the loop changes |
| a script (`scripts/`) | `wiki/Scripts.md` |
| a manifest key or default (`templates/manifest.yml`) | `wiki/Configuration.md` |
| a publication channel | `README.md` channels table, `wiki/Publishing-Channels.md`, `references/publishing.md` |
| a page format or contract (`references/`) | the matching wiki page, and the `examples/` base |
| the version | `plugin.json`, `marketplace.json` and the README badge together |

`sh tests/docs.sh` fails when a skill, agent, hook, script, channel or manifest
key is missing from the docs, or when versions disagree. CI runs it.

After merge, sync the wiki sources to `gotcha.wiki.git` (see `wiki/Contributing.md`).

## Checks before pushing

```sh
claude plugin validate .
sh tests/hooks.sh && sh tests/docs.sh
```

## Conventions

- Everything in the repository is English (code, docs, commits).
- Hooks and scripts are POSIX `sh`; `jq` optional.
- Rules live in `references/`; skills are procedures that point at them.
- Never push to `main`: branch, PR, wait for CI.
