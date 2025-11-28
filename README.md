# Archive Commits Script

This script archives Git commits from multiple repositories and generates markdown files for each commit, suitable for publishing on static site generators.

## Features

- **Multi-repository support**: Clone and fetch commits from multiple GitHub repositories
- **Multi-organization support**: Works with repositories from different GitHub organizations (e.g., `Xilinx`, `amd`, `torvalds`)
- **Smart cloning**: Skips cloning if a repository already exists locally
- **Multi-author filtering**: Filter commits by multiple author names
- **Duplicate detection**: Automatically detects and moves redundant commits based on commit hash (works across forks and different repos)
- **Flexible branching**: Support for different branches per repository
- **Structured output**: Generates markdown files with frontmatter metadata

## Configuration

Edit the arrays at the top of `archive_commits.sh`:

### Authors
```bash
author=("nishad.saraf" "nishads")
```
List of author usernames/emails to filter commits by.

### Repositories
```bash
repos=( "Xilinx/aie-rt"
    "amd/xdna-driver"
    "torvalds/linux"
    ...
)
```
Format: `"org/repo"` - GitHub organization and repository name.

### Branches
```bash
branches=("xlnx_rel_v2022.1"
    "main"
    "master"
    ...
)
```
Must match the order of repositories in the `repos` array.

### Components
```bash
component=("Userspace driver"
    "AMD XDNA driver"
    "Linux kernel"
    ...
)
```
Description of each repository component. Must match the order of repositories.

## Usage

```bash
./archive_commits.sh
```

The script will:
1. Create/clean the `commits/` directory
2. Clone repositories to `repo/` directory (or skip if already exists)
3. Fetch latest commits from specified branches
4. Generate markdown files for each commit (split into files of 9 lines each)
5. Copy additional commits from `misc_commits/` if present
6. Detect and move redundant commits to `redundant/` directory

## Output Structure

```
helpers/
├── archive_commits.sh
├── commits/                   # Generated commit markdown files
│   ├── Xilinx_aie-rt_xlnx_rel_v2022.1_00.md
│   ├── torvalds_linux_master_00.md
│   └── ...
├── redundant/                 # Duplicate commits (same hash across repos/forks)
│   └── Xilinx_linux-xlnx_master_00.md
├── repo/                      # Cloned repositories
│   ├── aie-rt/
│   ├── linux/
│   └── ...
└── misc_commits/              # Optional: manually curated commits
    └── custom_commit_00.md
```

## Markdown Format

Each generated markdown file contains:

```markdown
---
date: '2024-08-19'
title: 'dmaengine: amd: qdma: Add AMD QDMA driver'
github: 'https://github.com/Xilinx/linux-xlnx/commit/73d5fc92a11cacb73a1aac0b5793c47e48c5b537'
external: ''
component: 'Linux kernel'
company: 'Xilinx'
showInProjects: false
---
```

## Duplicate Detection

The script detects redundant commits by comparing commit hashes (40-character hex strings). This works across:
- Forked repositories (e.g., `Xilinx/linux-xlnx` and `torvalds/linux`)
- Cherry-picked commits
- Same repository appearing multiple times with different branches

Redundant commits are automatically moved to the `redundant/` folder.

## Requirements

- Bash shell
- Git
- Internet connection for cloning repositories
- Write access to the current directory

## Notes

- The script uses `pushd`/`popd` for directory navigation
- Failed clones are skipped with error messages
- Empty log files are handled gracefully
- The script is idempotent - safe to run multiple times

## License

See LICENSE file in this repository.

