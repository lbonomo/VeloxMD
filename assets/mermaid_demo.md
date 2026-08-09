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

Some text after the diagrams.
