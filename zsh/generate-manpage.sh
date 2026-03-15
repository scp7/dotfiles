#!/usr/bin/env bash
# Generates a man page from aliases.conf metadata
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$SCRIPT_DIR/aliases.conf"
MANDIR="${HOME}/.local/share/man/man1"
OUTPUT="$MANDIR/aliases.1"

if [[ ! -f "$CONF" ]]; then
  echo "Error: $CONF not found" >&2
  exit 1
fi

mkdir -p "$MANDIR"

DATE=$(date +"%B %Y")

awk -v date="$DATE" '
BEGIN {
  FS = "|"
  print ".TH ALIASES 1 \"" date "\" \"dotfiles\" \"Custom Shell Reference\""
  print ".SH NAME"
  print "aliases \\- custom shell aliases and functions"
  print ".SH DESCRIPTION"
  print "Quick reference for shell aliases and functions defined in ~/.zshrc."
  print ""
  print "Sections group related commands. Run"
  print ".B man aliases"
  print "anytime to refresh your memory."
  n = 0
  section_count = 0
}

/^#/ || /^$/ { next }

{
  name = $1
  section = $2
  desc = $3
  # Trim whitespace
  gsub(/^[ \t]+|[ \t]+$/, "", name)
  gsub(/^[ \t]+|[ \t]+$/, "", section)
  gsub(/^[ \t]+|[ \t]+$/, "", desc)

  if (section != current_section) {
    cmd = "printf \"%s\" \"" section "\" | tr \"[:lower:]\" \"[:upper:]\""
    cmd | getline upper
    close(cmd)
    print ""
    print ".SH " upper
    current_section = section
  }

  print ".TP"
  print ".B " name
  print desc
}

END {
  print ""
  print ".SH FILES"
  print ".TP"
  print ".B ~/.zshrc"
  print "Main shell configuration"
  print ".TP"
  print ".B ~/.zsh_local"
  print "Local overrides (not in repo)"
  print ".SH NOTES"
  print "Regenerate this page after editing zsh/aliases.conf by running:"
  print ".PP"
  print ".RS"
  print ".B zsh/generate-manpage.sh"
  print ".RE"
}
' "$CONF" > "$OUTPUT"

echo "Man page written to $OUTPUT"
echo "View with: man aliases"
