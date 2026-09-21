---
inclusion: always
---

# Git Branch Management Workflow

When starting a new fix or feature:
1. **Update local main branch**:
   ```bash
   git checkout main
   git pull origin main
   ```
2. **Create a new branch from main**:
   ```bash
   git checkout -b <type>/<short-description>
   ```
   *(e.g., `fix/text-selection-rendering`, `feature/mermaid-diagrams`)*

When the fix/feature is finished:
1. **Commit changes**:
   ```bash
   git add .
   git commit -m "<type>: <brief description>"
   ```
2. **Push to origin**:
   ```bash
   git push -u origin <branch-name>
   ```
3. **Create a Pull Request on origin**:
   ```bash
   gh pr create --base main --head <branch-name> --title "<PR Title>" --body "<PR Description>"
   ```
