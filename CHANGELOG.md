# Changelog

## 0.3.0 - 2026-08-04

### ✨ Features
- **Document Footer**: Added a comprehensive footer bar displaying document statistics
  - Real-time statistics: words, lines, characters, headings, links, code blocks
  - **Token counter** using industry-standard OpenAI tokenization algorithm
  - Software version display
  - Automatic update on file reload/change
  - Footer only visible when a document is open

### 🔢 Token Calculation
- Implemented hybrid token estimation algorithm based on OpenAI's standard
- Formula: Average of character-based (1 token ≈ 4 chars) and word-based (1 token ≈ 0.75 words) methods
- Useful for estimating costs in LLM APIs

### 📊 Document Statistics
- Words count
- Lines count
- Total characters
- Heading count
- External links count
- Code blocks count

---

## 0.2.0 - 2026-07-30

- Minor version bump from 0.1.1 to 0.2.0.
- Aligned Linux CMake project version with pubspec version.

