#!/usr/bin/env bash
set -uo pipefail

repo=$(CDPATH= cd -P -- "$(dirname -- "$0")/.." && pwd) || exit 1
cd -- "$repo" || exit 1

status=0
python3 - <<'PY' || status=1
from collections import defaultdict
from html import unescape
from pathlib import Path
import os
import re
import subprocess
import unicodedata
from urllib.parse import unquote

root = Path.cwd()
files = sorted({
    Path(os.fsdecode(name))
    for name in subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"]
    ).split(b"\0")
    if name and Path(os.fsdecode(name)).is_file()
})
errors = []

scripts = [path for path in files if path.suffix == ".sh"]
launcher = Path("skills/statechart/scripts/statechart")
before = len(errors)
for shell, path in [("bash", path) for path in scripts] + [("sh", launcher)]:
    if subprocess.run([shell, "-n", str(path)]).returncode:
        errors.append(f"{path}: {shell} -n failed")
if len(errors) == before:
    print(f"PASS shell syntax ({len(scripts)} Bash scripts, 1 sh launcher)")

frontmatter = re.compile(r"\A---[ \t]*\n(.*?)^---[ \t]*$", re.M | re.S)
readme = Path("README.md").read_text(encoding="utf-8")
skills = sorted(Path("skills").glob("*/SKILL.md"))
playbooks = sorted(Path("skills/poteto-mode/playbooks").glob("*.md"))
before = len(errors)
for skill in skills:
    metadata = frontmatter.match(skill.read_text(encoding="utf-8"))
    names = re.findall(r"^name:[ \t]*(.+)$", metadata[1], re.M) if metadata else []
    if len(names) != 1 or names[0].strip().strip("\"'") != skill.parent.name:
        errors.append(f"{skill}: expected a single frontmatter name {skill.parent.name!r}")
for label, count in (("技能", len(skills)), ("playbook", len(playbooks))):
    declared = re.findall(rf"^##[ \t]+(\d+)[ \t]*个[ \t]*{label}", readme, re.M)
    if declared != [str(count)]:
        errors.append(f"README.md: {label} count {declared or 'missing'}, found {count}")
if len(errors) == before:
    print(f"PASS skill metadata and README counts ({len(skills)} skills, {len(playbooks)} playbooks)")

# Mask examples while keeping source line numbers. Inline code still appears
# in headings and link labels, so mask it only when extracting destinations.
def blank(match):
    return re.sub(r"[^\n]", " ", match[0])


def rendered_source(text):
    text = frontmatter.sub(blank, text, count=1)
    text = re.sub(r"<!--.*?-->", blank, text, flags=re.S)
    fence = ""
    for line in text.splitlines(keepends=True):
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if fence:
            if marker and marker[1].startswith(fence) and not marker[2].strip():
                fence = ""
            yield "\n" if line.endswith("\n") else ""
        elif marker:
            fence = marker[1]
            yield "\n" if line.endswith("\n") else ""
        else:
            yield line


destination = r"(?P<dest><[^<>\n]*>|(?:\\.|[^\s()\\]|\((?:\\.|[^\s()\\])*\))*)"
title = r"""(?:[ \t\n]+(?:"[^"\n]*"|'[^'\n]*'|\([^()\n]*\)))?"""
inline_link = re.compile(
    r"(?<!\\)\[(?P<label>(?:\\.|[^\[\]\\]|\[[^\[\]]*\])*)\]\([ \t\n]*"
    + destination + title + r"[ \t\n]*\)"
)
reference = re.compile(r"^ {0,3}\[(?!\^)[^\]\n]+\]:[ \t\n]*" + destination, re.M)
inline_code = re.compile(r"(?<!`)(`+)(?!`).*?(?<!`)\1(?!`)", re.S)
html_anchor = re.compile(r"""<a\b[^>]*?\s(?:id|name)\s*=\s*(["'])(.*?)\1""", re.I)
html_link = re.compile(r"""<(?:a|img)\b[^>]*?\s(?:href|src)\s*=\s*(["'])(?P<dest>.*?)\1""", re.I)


def markdown_anchors(text):
    anchors = {unescape(match[2]) for match in html_anchor.finditer(inline_code.sub(blank, text))}
    repeats = defaultdict(int)
    previous = ""
    for line in text.splitlines():
        heading = re.match(r"^ {0,3}#{1,6}[ \t]+(.+?)(?:[ \t]+#+)?[ \t]*$", line)
        if heading:
            label = heading[1]
        elif previous and re.fullmatch(r" {0,3}(?:=+|-+)[ \t]*", line):
            label = previous
        else:
            previous = line.strip()
            continue
        previous = ""
        label = inline_link.sub(r"\g<label>", label)
        label = re.sub(r"<[^>]+>", "", label)
        label = re.sub(r"(?<!\w)(_+)(?=\S)(.+?)(?<=\S)\1(?!\w)", r"\2", label)
        slug = "".join(
            char for char in unescape(label).strip().lower()
            if char in " _-" or unicodedata.category(char)[0] in "LMN"
        ).replace(" ", "-")
        count = repeats[slug]
        anchor = slug if count == 0 else f"{slug}-{count}"
        while anchor in repeats and anchor != slug:
            count += 1
            anchor = f"{slug}-{count}"
        repeats[slug] = count + 1
        repeats[anchor] = max(repeats[anchor], 1)
        anchors.add(anchor)
    return anchors


markdown = {
    path: path.read_text(encoding="utf-8") for path in files if path.suffix.lower() == ".md"
}
rendered = {path: "".join(rendered_source(text)) for path, text in markdown.items()}
anchors = {path.resolve(): markdown_anchors(text) for path, text in rendered.items()}
before = len(errors)
links = 0
for source, text in rendered.items():
    visible = inline_code.sub(blank, text)
    for pattern in (inline_link, reference, html_link):
        for match in pattern.finditer(visible):
            dest = unescape(re.sub(r"\\([^\w\s])", r"\1", match["dest"].strip("<>")))
            if not dest or dest.startswith("/") or re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", dest):
                continue
            path, _, fragment = dest.partition("#")
            path = path.split("?", 1)[0]
            target = (source.parent / unquote(path)).resolve() if path else source.resolve()
            links += 1
            line = visible.count("\n", 0, match.start()) + 1
            if not target.exists() or not (target == root or root in target.parents):
                errors.append(f"{source}:{line}: broken relative link {dest!r}")
            elif fragment:
                if target.is_dir():
                    target /= "README.md"
                if target.suffix.lower() == ".md" and unquote(fragment) not in anchors.get(target, set()):
                    errors.append(f"{source}:{line}: missing anchor in {dest!r}")
if len(errors) == before:
    print(f"PASS Markdown links and anchors ({links} local links in {len(markdown)} files)")

before = len(errors)
for source, text in markdown.items():
    previous = ""
    line = 1
    for block in re.split(r"\n[ \t]*\n", text):
        for field in re.finditer(r"\bCwd\b", block):
            # Prose may document the absence of this field.
            prefix = block[max(block.rfind("。", 0, field.start()), block.rfind("\n", 0, field.start())) + 1:field.start()]
            if re.search(r"(?:不支持|不接受|不要|不得|不能|禁止|无需|没有|do not|does not)[^，,。]*$", prefix, re.I):
                continue
            assignment = re.match(r"""["'`]?[ \t]*[:=]""", block[field.end():])
            if re.search(r"\brun_command\b", block) or (assignment and re.search(r"\brun_command\b", previous)):
                errors.append(f"{source}:{line + block.count(chr(10), 0, field.start())}: run_command Cwd instruction")
        previous = block
        line += block.count("\n") + 2
if len(errors) == before:
    print("PASS run_command instructions (no Cwd argument)")

if errors:
    for error in errors:
        print(f"FAIL {error}")
    raise SystemExit(1)
PY

if command -v agy >/dev/null 2>&1; then
  if agy plugin validate "$repo"; then
    echo 'PASS agy plugin validate'
  else
    echo 'FAIL agy plugin validate' >&2
    status=1
  fi
else
  echo 'SKIP agy plugin validate (agy is not on PATH)'
fi
exit "$status"
