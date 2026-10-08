# BuildSweep

**Make room on your Mac without guessing which development files are safe to remove.**

## The problem

Compilers, IDEs, and coding tools leave build files and caches behind. A large work folder may
hold those files beside source code, active worktrees, and records you need to keep. Its size
does not tell you which parts are safe to remove.

An AI assistant can help find a large folder, but a one-off guess from its name and size cannot
tell whether another project needs it. Repeating that search whenever the disk fills up is slow
and inconsistent.

## How BuildSweep helps

The planned app will scan only folders you choose. For an item it supports, it will look for
evidence from the tool or project, show any project connection it can verify, and explain how
the item could be rebuilt or downloaded again. If a fact needed for cleanup is unknown, it will
show that uncertainty and leave the item out of cleanup.

You will choose the exact items to remove. BuildSweep will check them again before moving them
to the macOS Trash. It will not clean a whole work folder just because some files inside it can
be rebuilt.

**Available today:** a read-only app that inspects one Rust project you choose. It shows why it
recognized Cargo build output and gives a qualified size result. It cannot remove files yet.

## Example: a Rust project

```text
my-rust-project/
├── Cargo.toml
└── target/
    └── CACHEDIR.TAG
```

Choose `my-rust-project` in the current app. BuildSweep checks that `Cargo.toml` is a real file,
`target` is a real directory, and `CACHEDIR.TAG` has Cargo's expected signature. Only then does
it report the `target` output and its size, or explain why the size could not be fully measured.
It does not delete anything.

## What comes next

Rust, Swift, and Xcode lead the first useful cleanup release. Python, Java and Android, and other
tool caches follow. Codex and other agent work folders will be shown as mixed storage: BuildSweep
should identify supported build output while protecting source, worktrees, and retained records.
The planned results window, menu bar, Dock actions, and widget will share one scan and review
workflow. The current menu bar offers Open and Quit. BuildSweep targets macOS 13 and later;
release validation is pending.

## Read more

- [Product plan and coverage](docs/PRODUCT.md)
- [Safety rules and exclusions](docs/SAFETY.md)
- [Architecture and current implementation](docs/ARCHITECTURE.md)
- [Design decisions](docs/decisions/README.md)
