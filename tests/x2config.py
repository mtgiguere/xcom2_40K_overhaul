"""Minimal parser for XCOM 2 config (.ini) and localization (.int) files.

XCOM ini files differ from stock INI:
  * keys may repeat; `+Key=` appends, `-Key=` removes, `.Key=` sets, `!Key=` clears
  * a trailing `\\` continues the value on the next line
  * section headers look like `[TemplateName X2SomeTemplate]` or `[Package.ClassName]`
  * localization files may be UTF-8 (repo) or UTF-16 (built mod)
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

_SECTION_RE = re.compile(r"^\[(?P<name>[^\]]+)\]\s*$")
_KV_RE = re.compile(r"^(?P<op>[+\-.!]?)(?P<key>[A-Za-z_][A-Za-z0-9_\[\]]*)\s*=\s*(?P<value>.*)$")


@dataclass
class Section:
    name: str
    entries: list[tuple[str, str, str]] = field(default_factory=list)  # (op, key, value)

    def values(self, key: str) -> list[str]:
        """All values for `key` whose op is '+', '.' or '' (i.e. not a removal)."""
        return [v for op, k, v in self.entries if k == key and op != "-"]

    def first(self, key: str) -> str | None:
        vals = self.values(key)
        return vals[0] if vals else None

    @property
    def template_name(self) -> str | None:
        """For `[Foo X2BarTemplate]` sections returns `Foo`, otherwise None."""
        parts = self.name.split()
        return parts[0] if len(parts) == 2 else None

    @property
    def template_class(self) -> str | None:
        parts = self.name.split()
        return parts[1] if len(parts) == 2 else None


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return raw.decode("utf-16")
    return raw.decode("utf-8-sig")


def parse_ini(path: Path) -> list[Section]:
    sections: list[Section] = []
    current: Section | None = None
    pending = ""
    for raw_line in read_text(path).splitlines():
        line = pending + raw_line.rstrip()
        pending = ""
        if line.endswith("\\\\"):
            pending = line[:-2]
            continue
        stripped = line.strip()
        if not stripped or stripped.startswith(";"):
            continue
        m = _SECTION_RE.match(stripped)
        if m:
            current = Section(m.group("name").strip())
            sections.append(current)
            continue
        m = _KV_RE.match(stripped)
        if m and current is not None:
            current.entries.append((m.group("op"), m.group("key"), m.group("value").strip()))
    return sections


def sections_of_class(sections: list[Section], template_class: str) -> list[Section]:
    return [s for s in sections if s.template_class == template_class]


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def struct_field(value: str, name: str) -> str | None:
    """Extract `name=...` from an Unreal struct literal like `(A=1, B="x", C=(D=2))`."""
    m = re.search(rf"(?<![A-Za-z0-9_]){re.escape(name)}\s*=\s*(\"[^\"]*\"|'[^']*'|[^,()]*)", value)
    return unquote(m.group(1)) if m else None
