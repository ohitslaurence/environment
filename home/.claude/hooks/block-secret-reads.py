#!/usr/bin/env python3
"""Block commands that print plaintext secrets to the transcript.

PreToolUse hook for Bash. Exit 2 => the tool call is refused and stderr is shown
to the model, so it must find another way rather than silently proceeding.

Why this exists: on 2026-08-07 an agent ran `sst secret list --stage production`
to verify an unrelated guard, and every production secret — a live Modern
Treasury key, the liabilities JWT signing secret, a treasury xpub — was printed
into the session transcript and had to be rotated. The command was chosen
*because* it was read-only. Read-only is not the same as safe: the danger is the
output, not the mutation.

This blocks reads whose entire purpose is to emit a credential in plaintext. It
deliberately does NOT try to block every possible leak — an agent that wants a
secret can always find another route. It removes the easy, plausible-looking
mistakes that a careful agent still walks into.

Bypass (for a human, knowingly, in their own terminal — never for an agent):
    CLAUDE_ALLOW_SECRET_READ=1 <command>
"""

import json
import re
import sys

# Each entry: (compiled pattern, what it would dump).
# Patterns match anywhere in the command so `bun sst ...`, `cd x && ...`, and
# pipelines are all covered.
RULES: list[tuple[re.Pattern[str], str]] = [
    (
        re.compile(r"\bsst\s+secrets?\s+(list|get)\b"),
        "every SST secret for the stage, in plaintext",
    ),
    (
        re.compile(r"\baws\s+secretsmanager\s+get-secret-value\b"),
        "a Secrets Manager secret value",
    ),
    (
        re.compile(r"\baws\s+ssm\s+get-parameters?\b.*--with-decryption\b"),
        "a decrypted SSM SecureString",
    ),
    (
        re.compile(r"\baws\s+kms\s+decrypt\b"),
        "KMS plaintext output",
    ),
    (
        re.compile(r"\bgh\s+secret\s+list\b"),
        "GitHub Actions secret names/values",
    ),
    (
        re.compile(r"\b(printenv|env)\b(?!\s*\|)\s*$"),
        "the full environment, which usually carries credentials",
    ),
]


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # Never fail closed on a malformed payload — that would wedge Bash.

    if payload.get("tool_name") != "Bash":
        return 0
    command = str(payload.get("tool_input", {}).get("command", ""))
    if not command:
        return 0
    if "CLAUDE_ALLOW_SECRET_READ=1" in command:
        return 0

    for pattern, what in RULES:
        if pattern.search(command):
            print(
                f"BLOCKED: this command prints {what} into the transcript, where it "
                f"is permanently exposed and must then be rotated.\n"
                f"Matched: {pattern.pattern}\n"
                f"Read-only is not safe when the output IS the secret. If you need to "
                f"know a secret EXISTS, check its name or a hash, never its value. "
                f"Ask the user to run it themselves if the value is genuinely needed.",
                file=sys.stderr,
            )
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
