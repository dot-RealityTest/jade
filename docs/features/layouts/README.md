# Layouts

Jade can apply named pane/tab layouts to a worktree on demand. Layouts live in-repo under `{Project.path}/.jade/layouts/` so they can be checked in alongside the project.

```mermaid
flowchart TB
  Files[".jade/layouts/*.yaml"] --> Picker[Top-bar layout picker<br/>shown when ≥1 layout exists]
  Picker --> Confirm{Confirm}
  Confirm -->|yes| Build[LayoutWorkspaceBuilder<br/>build SplitNode/TabArea tree]
  Build --> Replace[Close current tabs<br/>apply new tree]
```

## Pages

| Page | What's in it |
| --- | --- |
| [Schema](schema.md) | Fields, single pane, splits, nested splits, JSON form |
| [Examples](examples.md) | Worked examples: single, side-by-side, stacked, tri-row, quad, dev |

## Behavior at a glance

- Each file under `.jade/layouts/` defines one named layout. The file name (without extension) is the layout's name.
- Supported extensions: `.yaml`, `.yml`, `.json`.
- Layouts are **never auto-applied** on project open — the user picks one explicitly.
- Selecting a layout asks for confirmation. On accept, all current terminals/tabs in that worktree are closed and the layout is applied.

## File location

```
<project-root>/.jade/layouts/
  dev.yaml
  release.yaml
  scratch.json
```
