# Nix Rules

## Environment

- Flakes enabled

---

## Style

- Prefer small reusable modules
- Avoid large inline strings
- Prefer source files over embedded config
- Keep modules focused and composable
- Prefer explicit configuration over implicit behavior

---

## Home Manager

- Prefer `home.file.<path>.source` over embedded `text` when possible
- Keep declarative configuration reproducible
- Separate large configs into dedicated files
- Avoid deeply nested inline strings

---

## Flakes

- Keep inputs minimal
- Prefer explicit package references
- Prefer stable inputs unless unstable is required
- Avoid unnecessary overlays
- Keep outputs easy to understand

---

## Debugging

- Inspect the full error trace before modifying configuration
- Preserve indentation carefully
- Verify attribute paths before editing
- Prefer incremental fixes over rewrites
- Read existing module structure before refactoring
- Verify whether errors originate from evaluation or runtime behavior

---

## Editing

- Avoid rewriting working modules unnecessarily
- Preserve existing formatting style
- Prefer minimal diffs
- Avoid unrelated refactors during debugging
- Verify imports and module paths before changes

---

## Best Practices

- Prefer reusable modules over duplicated configuration
- Prefer declarative configuration over imperative scripts
- Prefer reproducible environments
- Prefer explicit dependencies
- Keep configuration discoverable and searchable

---

## Do Not

- Do not embed large YAML or JSON blobs inline unless necessary
- Do not modify lock files manually unless intentional
- Do not assume attribute existence without verification
- Do not replace working flakes structure without understanding dependencies