# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pure Swift YAML parser with no external dependencies. Parses YAML strings into a `Node` tree (scalar, mapping, sequence). Supports block and flow styles, quoted strings, comments, and nested structures. Designed for use cases like schema DSL parsing (database field definitions with inline annotations).

## Build & Test

```bash
# Build
swift build

# Run all tests
swift test 2>&1 | tail -5

# Run a single test
swift test --filter YAMLTests.ComposeTests/simpleMapping
```

### Filter by category (regex on Suite/test path)

```bash
# By YAML spec chapter
swift test --filter "SpecChapter2"     # Chapter 2: Language Overview
swift test --filter "SpecChapter5"     # Chapter 5: Character Productions
swift test --filter "SpecChapter6"     # Chapter 6: Structural Productions
swift test --filter "SpecChapter7"     # Chapter 7: Flow Style Productions
swift test --filter "SpecChapter8"     # Chapter 8: Block Style Productions
swift test --filter "SpecChapter9"     # Chapter 9: Document Stream
swift test --filter "SpecChapter10"    # Chapter 10: Recommended Schemas

# By feature area
swift test --filter "SpecComplexKey"   # Explicit ? keys, complex keys
swift test --filter "SpecMultiline"    # Multi-line scalar folding
swift test --filter "SpecEscape"       # Escape sequences
swift test --filter "SpecTag"          # Tag parsing
swift test --filter "SpecDirective"    # %YAML, %TAG directives
swift test --filter "SpecAnchor"       # Anchors & aliases
swift test --filter "SpecComment"      # Comment handling
swift test --filter "SpecEmpty"        # Empty nodes
swift test --filter "SpecIndentation"  # Indentation rules
swift test --filter "SpecJSON"         # JSON compatibility

# All spec tests vs regression tests
swift test --filter "Spec"             # All YAML 1.2.2 spec tests
swift test --filter "EdgeCase|Error|Compose|Schema|LineEnding"  # Regression tests

# Show only failures
swift test 2>&1 | grep -E "failed|recorded an issue"
```

Swift tools version: 6.2. No platform restrictions specified.

## Architecture

The parser uses a classic **Scanner → Parser → Node** pipeline:

1. **Scanner** (`Scanner.swift`) — Tokenizer that converts a YAML string into a `Token` stream. Tracks indentation levels via an indent stack to emit implicit block structure tokens (`blockMappingStart`, `blockSequenceStart`, `blockEnd`). Maintains a `flowLevel` counter to switch between block and flow context parsing rules. Characters are consumed from a `[Character]` array with position/line/column tracking.

2. **Parser** (`Parser.swift`) — Recursive descent parser that consumes tokens from Scanner and builds a `Node` tree. Uses single-token lookahead (`peeked`). Handles block mappings, block sequences, flow sequences (`[...]`), and flow mappings (`{...}`).

3. **Compose** (`Compose.swift`) — Public entry point. The `compose(yaml:)` function creates a Parser and returns the root `Node`.

### Key Types

- **`Node`** (`Node.swift`) — Enum with `.scalar(Scalar)`, `.mapping(Mapping)`, `.sequence(Sequence)` cases
- **`Node.Scalar`** — Holds `string` value and optional `Mark` position
- **`Node.Mapping`** — Ordered key-value pairs (`RandomAccessCollection`), subscriptable by string key
- **`Node.Sequence`** — Ordered node list (`RandomAccessCollection`)
- **`Token`** — Internal enum for scanner output (block/flow structure tokens + scalar values with `ScalarStyle`)
- **`Mark`** — 1-based line/column position in source
- **`YAMLError`** — Scanner, parser, and unexpected-end-of-input errors with `Mark` positions

### Design Notes

- All public types are `Sendable` and `Hashable`
- `Mapping` preserves insertion order (uses internal `Pair` array, not `Dictionary`)
- `Token` and `Scanner` are internal — only `Node`, `Mark`, `YAMLError`, and `compose()` are public API
