#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "==> Generating Xcode project with XcodeGen from project.yml..."
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate
elif [ -x "/opt/homebrew/bin/xcodegen" ]; then
    /opt/homebrew/bin/xcodegen generate
else
    echo "Error: xcodegen is not installed. Install with: brew install xcodegen" >&2
    exit 1
fi

echo "==> BetterScreenShot.xcodeproj generated successfully!"
