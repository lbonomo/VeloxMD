# Git Branch Management Workflow

This rule defines the standard Git workflow for managing fixes and features in this project.

## Workflow Rules

### 1. Starting a New Fix or Feature
Before starting work on any fix, feature, or enhancement:

1. **Update local main branch**:
   Ensure local `main` is up to date with `origin/main`.
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a new branch from main**:
   Create and switch to a dedicated topic branch using a descriptive prefix (`fix/`, `feature/`, etc.).
   ```bash
   git checkout -b <type>/<short-description>
   ```
   *Examples:* `fix/text-selection-rendering`, `feature/mermaid-diagrams`

---

### 2. Completing a Fix or Feature
When the fix or feature development and testing are finished:

1. **Commit changes**:
   Stage and commit all relevant modifications with a clear, descriptive commit message.
   ```bash
   git add .
   git commit -m "<type>: <brief description of changes>"
   ```

2. **Push branch to origin**:
   Push the topic branch to the remote repository `origin`.
   ```bash
   git push -u origin <branch-name>
   ```

3. **Create a Pull Request (PR) on origin**:
   Open a pull request merging the topic branch into `main`.
   ```bash
   gh pr create --base main --head <branch-name> --title "<PR Title>" --body "<PR Description>"
   ```
