# Project planning templates

Reusable markdown scaffolds for Jade planning docs. Copy a template, fill the `{{placeholders}}`, and save to the path noted in each file header.

| Template | Copy to | Use when |
| --- | --- | --- |
| [decision-record-template.md](decision-record-template.md) | `docs/decisions/0001-slug.md` | An architectural or product choice needs a durable record |
| [feature-spec-template.md](feature-spec-template.md) | `docs/specs/slug.md` | Agreeing on behavior before implementation |
| [project-status-template.md](project-status-template.md) | `docs/status.md` | Periodic release-readiness or milestone review |
| [roadmap-template.md](roadmap-template.md) | `docs/roadmap.md` | Now / Next / Later priorities (keep `status.md` milestone aligned with **Now**) |

## Conventions

- Number decision records in order (`0001`, `0002`, …). Once **Accepted**, treat as immutable — supersede with a new record instead of editing history.
- Write feature specs before building; spin out a decision record when a spec surfaces a real architectural fork.
- Update **Updated** dates on status and roadmap when you review them.
- No emojis in filled docs; SF Symbol names in HTML comments are for macOS UI alignment only.

## Related

- [Obsidian vault templates](obsidian/README.md) — note shapes Jade writes to your vault
- [Product scope](../developer/product-scope.md) — what Jade ships vs defers
- [Architecture](../architecture.md) — current system inventory
