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
| `birb merge <PR>`  | Merge GitHub PRs locally with clean commit messages |
| `birb review <PR>` | AI-powered PR review via local Claude Code |

## Requirements

- `gh` (GitHub CLI)
- `git`
- `jq`
- `claude` (Claude Code CLI) — only for `birb review`

## Usage

```bash
birb merge 42                    # Merge PR #42 into its base branch
birb merge 42 --switch=main      # Merge into a different branch
birb merge 42 --no-commit        # Merge without committing
birb merge 42 --force-squash     # Force squash even with multiple authors

birb merge 42 --dry-run          # Preview every mutating command
birb merge 42 --no-push          # Skip pushing branch + tag
birb merge 42 --no-close-pr      # Skip closing the PR on GitHub
birb merge 42 --no-close-issue   # Skip closing any linked issue
birb merge 42 --no-project-update # Skip moving the project item to "Done"

birb review 42                       # Review PR #42 (senior-engineer persona)
birb review 42 --persona=security    # security / perf / ux / senior
birb review 42 --checkout            # Check out the PR branch locally first
```

## `birb merge` end-to-end flow

After the local squash / merge commit + version bump, `birb merge` wraps the
PR up remotely:

1. **Push** `<target_branch>` to the remote, then push the new tag explicitly
   (the script's tags are lightweight, so `--follow-tags` won't carry them).
2. **Close the PR** with a comment of the form
   `Squash-merged into \`main\` as <sha> (<tag>).` and delete the head branch
   when the PR head lives in the same repo (not a fork).
3. **Close any linked issue** referenced in the PR body via a GitHub closing
   keyword (`Closes #N`, `Fixes #N`, `Resolves #N` and their variants), with
   `--reason completed` and a comment linking back to the merge.
4. **Move the linked project item to "Done"** — discovers the owner's
   projects, finds an item linked to the PR or to any closing-keyword issue,
   then resolves the `Status` field id and `Done` option id by case-
   insensitive name match. Project board updates need the `project` OAuth
   scope; grant it with `gh auth refresh -s project,read:project`.
5. **Thank the author** (interactive, optional).

Every step is idempotent and skippable:

- `--dry-run` prints each command and changes nothing.
- `--no-push` / `--no-close-pr` / `--no-close-issue` / `--no-project-update`
  disable individual steps.
- An already-closed PR, an already-closed issue, or a project item that has
  no matching entry is reported as skipped rather than failing the run.
- Push failure aborts the run (every subsequent step depends on origin
  having the merge). PR close, issue close, and project board failures are
  logged as warnings and the run continues.

The final summary prints what landed: merge SHA, tag, what was pushed, PR
close status, closed/skipped/failed issues, project board moves, dependent
branches replayed, and thank-you status.

## Stacked PRs and the squash phantom conflict

A squash-merge rebuilds the PR's changes as one new commit that is an
ancestor of nothing. Any branch still holding the *original* commits now
shares no recent ancestor with the target, so git compares both sides from
before the squash and reports the same lines edited twice — a conflict on
identical content. `birb merge` handles this on two fronts:

- **Before the merge**, it finds every dependent branch and replays it after
  the merge with `git rebase --onto <target> <merged head sha>`, then
  force-pushes (`--force-with-lease`). Dependents are found two ways:
  by base ref (PRs stacked directly on the merged head) *and* by history
  containment — an open PR already based on the target branch whose head
  still contains the merged commits. The second case is the one that bites:
  once a dependent's base has been re-pointed (manually, or by an earlier
  `birb merge` further down the stack) it stops looking stacked while still
  carrying the commits, and nothing replays it. The conflict then surfaces
  on *its* merge, long after the run that caused it.
- **When `gh pr merge` refuses**, it reads the real `mergeable_state` instead
  of guessing. For `dirty` it looks for a recently squash-merged PR whose
  pre-merge head is still in this branch's history, names it, prints the
  exact recovery command, and offers to run it and retry the merge.
  `blocked`, `behind`, `draft` and `unknown` each get their own message.

Rebasing a dependent rewrites *its* head, so anything stacked on **that**
branch would be left behind in turn. Each successful replay therefore
queues the PRs based on the branch it just rewrote, with
`--onto <new parent head> <old parent head>`, and walks the stack
breadth-first down to 5 levels. A three-deep stack lands in one run.

### Finding the cut point

`--onto <cut>` only replays what comes *after* `<cut>`, so the cut has to be
the newest commit the branch carries that the target already has. Matching
merged PRs by head SHA finds only the ones merged straight from the branch
in front of you: a branch can carry several squashed ancestors, and the ones
further up the stack are usually rebased copies — same patch, different SHA.
Cutting at the oldest of them replays commits the target already has, which
conflicts again.

So the cut is found by `git patch-id`, which a rebase preserves: the newest
commit whose patch-id matches a commit already landed by a merged PR. The
same trick recovers a branch that was left behind by an earlier rewrite and
no longer descends from its recorded cut point at all — its cut is
recomputed against the branch it should be sitting on, rather than forcing a
rebase from a meaningless point.

A branch in a fork is never force-pushed — it's reported so its owner can
rebase.

## Manual verification

There is no automated test suite. To exercise the new flow safely, use a
throwaway PR in a personal repo:

| Scenario | Command | Expected |
|---|---|---|
| Preview only, no state change | `birb merge <N> --dry-run` | Every push / `gh ...` call printed as `[dry-run] …`. Working tree, remote, PR all unchanged. |
| Push but skip remote closes | `birb merge <N> --no-close-pr --no-close-issue --no-project-update` | Branch + tag pushed; PR still open; summary shows "skipped" for the rest. |
| PR with no `Closes #N` keyword | merge a PR whose body has no closing keyword | "No linked issue keyword found in PR body. Skipping." in the close-issue section. |
| Repo with no GitHub Project | run in a repo whose owner has no project | "No projects found for `<owner>`. Skipping." |
| Missing `project` OAuth scope | revoke project scope, then run | "Could not list projects for `<owner>` (missing 'project' scope?). Skipping." with the `gh auth refresh` hint. |
| Fork PR | merge a PR opened from a fork | PR closes **without** `--delete-branch` (gh doesn't try to delete the fork's branch). |
| Idempotent rerun | run twice in a row on the same PR | Second run reports "PR #N already merged on GitHub", "Issue #N already closed", and the project item update is a no-op. |
| Stacked dependent | PR B stacked on PR A, merge A | B re-targeted, replayed onto the target, force-pushed; summary shows "re-targeted + rebased". |
| Dependent already re-pointed | B's base set to `main` by hand, then merge A | B is still found (its head contains A's commits) and replayed; summary shows "rebased (carried these commits)". |
| Phantom conflict on merge | merge a PR whose head carries a squash-merged PR's commits | Diagnosis names the culprit PR, prints the `git rebase --onto` command, offers to run it, then retries the merge. |
| Several squashed ancestors | merge the top of a three-deep stack after the two below it landed | Cut point found by patch-id at the *newest* already-landed commit, not the oldest; replay leaves only the PR's own commits. |
| Three-deep stack | A ← B ← C, merge A | B replayed onto the target, then C replayed onto B's new head; C stays stacked on B and both merge clean. |
| Branch left behind | rebase B by hand without C, then merge B | C's cut point is recomputed by patch-id and it is replayed onto the target instead of failing. |
| Happy path | `birb merge <N>` end-to-end | Summary shows push ✔, PR closed ✔, issue closed ✔, project item moved ✔, thank-you posted ✔. |

