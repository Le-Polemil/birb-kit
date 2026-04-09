# birb-kit

Personal CLI toolkit.

## Install

```bash
brew install Le-Polemil/tools/birb-kit
```

Or manually:

```bash
git clone https://github.com/Le-Polemil/birb-kit.git
cd birb-kit
make install
```

## Commands

| Command | Description |
|---|---|
| `birb merge <PR>` | Merge GitHub PRs locally with clean commit messages |

## Requirements

- `gh` (GitHub CLI)
- `git`
- `jq`

## Usage

```bash
birb merge 42                    # Merge PR #42 into its base branch
birb merge 42 --switch=main      # Merge into a different branch
birb merge 42 --no-commit        # Merge without committing
birb merge 42 --force-squash     # Force squash even with multiple authors
```
