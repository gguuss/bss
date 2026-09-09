---
name: bss-engineering-discipline
description: >-
  Enforces software engineering rigor for Better Screen Shot (BSS) project:
  mandatory unit/integration tests for every feature, pre-implementation roadmap
  tracking in ROADMAP.md, semantic versioning with GitHub milestone tags, and
  up-to-date README documentation.
---

# BSS Engineering Discipline & Quality Standards

This skill ensures that Better Screen Shot (BSS) is built with professional software engineering discipline, avoiding "vibe coding" and preventing broken releases.

## Core Rules & Guardrails

### 1. Test-First Rigor (No Broken Stuff)
- **Every feature must have automated tests** before considering it complete.
- Verify both positive cases and edge cases (e.g., multi-monitor setups, permission denied states, pasteboard data consistency).
- Run `swift test` and ensure 100% pass rate before committing changes.

### 2. Roadmap-First Delivery
- **Every feature must be documented on `ROADMAP.md`** before implementation begins.
- Maintain strict prioritization:
  - **Milestone 1 (Core)**: Fast desktop & window capture to clipboard, menubar camera icon, bullseye drag selector, global hotkeys, first-run wizard.
  - **Milestone 2+ (Nice to Have)**: 5–60s video recording with system audio, secure gallery, cloud sharing.
- Update `ROADMAP.md` task checkboxes as features are designed, tested, and shipped.

### 3. Semantic Versioning & GitHub Milestones
- Every feature release milestone must bump semantic versioning (`vMAJOR.MINOR.PATCH`).
- Commit milestone achievements with clear conventional commit messages.
- Create git tags corresponding to the milestone (e.g., `git tag -a v1.0.0 -m "Release v1.0.0 - Core screenshot utility"`).
- Publish tags and commits to GitHub repository: `https://github.com/gguuss/bss`.

### 4. Comprehensive Documentation (`README.md`)
- Keep `README.md` continuously updated as the single source of truth for:
  - Features overview.
  - Menubar controls & bullseye drag interactions.
  - Default & configurable hotkeys.
  - Required macOS permissions and how to grant them.
  - Architecture and build instructions.
  - Checklist for Apple App Store submission.

### 5. Verified Packaging & Signing
- Validate bundle structure (`Better Screen Shot.app/Contents/Info.plist`, `MacOS/`, `Resources/`).
- Sign the application bundle (`codesign --force --deep --sign - --options runtime`) so it runs cleanly on macOS without quarantine corruption.
- Provide clear verification steps.
