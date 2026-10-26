# Contributing

## Layout of the plugin

```
.claude-plugin/   plugin.json · marketplace.json
skills/           the seven user-facing skills (gotcha-init, -recall, -investigate, -capture, -publish, -tidy, -lint)
agents/           gotcha-surveyor · gotcha-scribe · gotcha-publisher
hooks/            hooks.json + session-start.sh · track.sh · stop.sh · lib.sh
references/       the shared contracts: page-format · capture-contract · organization · publishing · diagrams
templates/        the page skeletons init copies from
scripts/          stats.sh · stale.sh · publish-check.sh · render-diagrams.sh
tests/            hooks.sh (smoke test) · docs.sh (docs drift check)
assets/           icon.svg, the source of .claude-plugin/icon.png
.github/          the CI workflow
examples/         payments-gateway — both layers, filled in
wiki/             the sources of this wiki
```

## README and wiki are living docs

They describe what the plugin ships, so they change in the **same PR** as the code. `tests/docs.sh` (a CI check) fails when a skill, agent, hook, script, channel or manifest key is missing from them, or when the versions disagree. The mapping of "what you change → what you update" is in [`CLAUDE.md`](https://github.com/DamienVauchel/gotcha/blob/main/.claude/CLAUDE.md).

## One authority per rule

The skills are **procedures**; the rules live in `references/`. Duplicating a rule in a skill would let the two drift — precisely the failure the base exists to prevent. Change the reference, not the skill, and point at it.

## Conventions

- **Everything in the repository is English**: code, comments, skills, agents, rules, docs, commit messages.
- Hooks and scripts are POSIX `sh`; `jq` is used when present, never required.
- Hooks must degrade silently and never loop (the Stop hook nudges once per turn).
- Diagrams follow the [house style](Diagrams) and must pass `render-diagrams.sh`.
- Keep `manifest.yml` keys **flat scalars** where hooks read them.

## Checks before a PR

```sh
claude plugin validate .                                 # manifests
sh tests/hooks.sh                                          # hooks smoke test
sh tests/docs.sh                                           # README and wiki match the plugin
sh -n hooks/*.sh scripts/*.sh tests/*.sh                   # syntax
cd examples/payments-gateway
sh ../../scripts/stats.sh gotchas                          # no unexpected flags
sh ../../scripts/publish-check.sh                          # fresh
sh ../../scripts/render-diagrams.sh docs/*.md docs/*/*.md  # every diagram renders
```

If you change a page format or a contract, update the example so it still demonstrates the current shape.

## Editing this wiki

The wiki sources live in [`wiki/`](https://github.com/DamienVauchel/gotcha/tree/main/wiki) so changes are **reviewed in PRs** like any other. GitHub serves a wiki from a separate repository, `gotcha.wiki.git`; to sync after merge:

```sh
git clone https://github.com/DamienVauchel/gotcha.wiki.git /tmp/gotcha-wiki
cp wiki/*.md /tmp/gotcha-wiki/
cd /tmp/gotcha-wiki && git add -A && git commit -m "sync wiki" && git push
```

Links between wiki pages use GitHub-wiki style (`[Text](Page-Name)`, no extension). Links into the repository use absolute URLs.
