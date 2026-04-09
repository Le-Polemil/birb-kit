# cli-tools

Personal CLI tools collection.

## Install

```bash
brew install Le-Polemil/tools/cli-tools
```

Or manually:

```bash
git clone https://github.com/Le-Polemil/cli-tools.git
cd cli-tools
make install
```

## Tools

| Command | Description |
|---|---|
| `gh-merge` | Merge GitHub PRs locally with clean commit messages (squash, multi-author support, thank-you comments) |

## Requirements

- `gh` (GitHub CLI)
- `git`
- `jq`

## Usage

```bash
gh-merge 42                    # Merge PR #42 into its base branch
gh-merge 42 --switch=main      # Merge into a different branch
gh-merge 42 --no-commit        # Merge without committing
gh-merge 42 --force-squash     # Force squash even with multiple authors
```
