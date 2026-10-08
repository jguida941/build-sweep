# BuildSweep

**Inspect development build output on macOS before deciding what to remove.**

Compilers, IDEs, package managers, and coding agents can leave gigabytes of build output and
caches behind. The difficult part is deciding which exact files can be removed. A large work
folder may hold generated data beside source code, Git worktrees, settings, and records another
tool or project still needs. A name, size, age, or one-off AI guess cannot settle that question.

BuildSweep is an evidence-based development artifact inspector. Its long-term goal is to help you
recover space from supported generated artifacts while keeping the decision and its limits clear.

## Planned app behavior

You will be able to:

1. **Discover** storage inside locations you approve.
2. **Identify** supported artifacts using project or tool-specific evidence.
3. **Explain** the observed size, known connections, regeneration requirements, and uncertainty.
4. **Review** exact items before cleanup, recheck them, then move approved items to the macOS Trash.

Finding a folder is not proof of what it contains. Recognizing build output does not authorize
cleanup, and being able to rebuild something does not guarantee recovery of its previous state.
Unknown items will be shown for inspection, but they cannot become
cleanup candidates just because they are large or old.

## What works today

BuildSweep currently inspects one selected Rust Cargo project in a read-only macOS app. For
example:

```text
my-rust-project/
├── Cargo.toml
├── src/
│   └── main.rs
└── target/
    ├── CACHEDIR.TAG
    └── debug/
```

After you choose the project folder, BuildSweep checks that `Cargo.toml` is a real regular
file, `target/` is a real directory, and `target/CACHEDIR.TAG` is a real regular file with
Cargo's expected signature. Only then does it report the `target/` directory and an estimated
allocated size. It states when the measurement is partial or unavailable. The app does not move
or delete files.

## What comes next

Rust, Swift, and Xcode lead the first planned cleanup release. Python, Java, Android, and other
development caches follow. Agent-created work areas, including Codex work folders, will be
treated as mixed storage: supported generated parts may be identified, while source, worktrees,
retained records, and unknown content remain protected. A missing project link will not be taken
as proof that an item is unused.

The planned results window, menu bar, Dock actions, and widget will share one scan and review
workflow. Today, the menu bar offers Open and Quit. BuildSweep targets macOS 13 and later;
release validation is still pending.

## Read more

- [Product plan and coverage](docs/PRODUCT.md)
- [Safety rules and exclusions](docs/SAFETY.md)
- [Architecture and current implementation](docs/ARCHITECTURE.md)
- [Design decisions](docs/decisions/README.md)
