# Mermaid demo

Some regular Markdown before the diagram.

## Flowchart

```mermaid
flowchart TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Check the logs]
    D --> B
    C --> E[Ship it]
```

## Sequence diagram

```mermaid
sequenceDiagram
    participant U as User
    participant V as VeloxMD
    U->>V: Open document.md
    V-->>U: Rendered Markdown
    U->>V: Scroll to diagram
    V-->>U: Rendered Mermaid diagram
```

## A normal code block (should NOT render as a diagram)

```dart
void main() {
  print('Hello, VeloxMD');
}
```

## Shell script

```sh
#!/bin/sh
echo "Hello from sh"
```

## Bash script

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "Hello from bash"
```

## SQL query

```sql
SELECT id, title
FROM todos
WHERE status = 'done';
```

## JSON

```json
{
  "name": "VeloxMD",
  "type": "demo"
}
```

## YAML

```yaml
name: VeloxMD
enabled: true
items:
  - markdown
  - mermaid
```

## TOML

```toml
[app]
name = "VeloxMD"
version = "0.5.0"
```

## Python

```python
def greet(name):
    return f"Hello, {name}"
```

## Go

```go
package main

import "fmt"

func main() {
    fmt.Println("Hello from Go")
}
```

## JavaScript

```js
console.log("Hello from JavaScript");
```

## Diff

```diff
- old line
+ new line
```

Some text after the diagrams and code blocks.
