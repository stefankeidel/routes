from __future__ import annotations
from pathlib import Path
from typing import Iterable, List, Optional, Dict, Any
import yaml


class RouteIndex:
    """
    Loads route manifest files from a `library/` directory and provides
    in-memory access and simple filters (by tag, by name, by id).

    Each manifest is expected to follow the shape used in this project:
    {
      "apiVersion": "bikerouter.de/v1",
      "kind": "Route",
      "metadata": {"name": ..., "description": ..., "tags": [...]},
      "spec": { ... }
    }

    Minimal contract:
    - inputs: path to a directory containing .yaml/.yml/.json route files
    - outputs: in-memory list of route dicts with fields: id, name, tags, filepath, raw
    - error modes: unreadable/invalid files are skipped and recorded in `errors`
    """

    def __init__(self, library_path: Optional[Path | str] = None):
        self.library_path = Path(library_path or Path.cwd() / "library")
        self.routes: List[Dict[str, Any]] = []
        self.errors: List[str] = []
        self.reload()

    def reload(self) -> None:
        """Clear and (re)load manifests from the library directory."""
        self.routes = []
        self.errors = []

        if not self.library_path.exists() or not self.library_path.is_dir():
            self.errors.append(f"library path does not exist: {self.library_path}")
            return

        for path in sorted(self.library_path.iterdir()):
            if path.is_file() and path.suffix.lower() in {".yaml", ".yml"}:
                try:
                    manifest = self._load_file(path)
                except Exception as exc:  # keep simple: record and continue
                    self.errors.append(f"failed to load {path}: {exc}")
                    continue

                if not isinstance(manifest, dict):
                    self.errors.append(f"unexpected manifest type in {path}: {type(manifest)}")
                    continue

                metadata = manifest.get("metadata", {}) or {}
                route_id = metadata.get("name") or path.stem
                name = metadata.get("name") or path.stem
                tags = metadata.get("tags") or []

                entry = {
                    "id": route_id,
                    "name": name,
                    "tags": list(tags),
                    "filepath": path,
                    "raw": manifest,
                }

                self.routes.append(entry)

    def _load_file(self, path: Path) -> Any:
        # Read YAML manifest files from the library. We only support YAML files
        # in the library; JSON and fenced content are no longer supported.
        text = path.read_text(encoding="utf-8")
        return yaml.safe_load(text)

    def all(self) -> List[Dict[str, Any]]:
        """Return all loaded route entries."""
        return list(self.routes)

    def get_by_id(self, route_id: str) -> Optional[Dict[str, Any]]:
        for r in self.routes:
            if r.get("id") == route_id:
                return r
        return None

    def filter_by_tag(self, tag: str) -> List[Dict[str, Any]]:
        return [r for r in self.routes if tag in (r.get("tags") or [])]

    def filter_by_name_contains(self, substring: str) -> List[Dict[str, Any]]:
        s = substring.lower()
        return [r for r in self.routes if s in (r.get("name", "").lower())]

    def search(self, tags: Optional[Iterable[str]] = None, name_contains: Optional[str] = None) -> List[Dict[str, Any]]:
        """Combined search helper. All provided filters are ANDed."""
        results = self.routes
        if tags:
            tags_set = set(tags)
            results = [r for r in results if tags_set.issubset(set(r.get("tags") or []))]
        if name_contains:
            s = name_contains.lower()
            results = [r for r in results if s in (r.get("name", "").lower())]
        return results


__all__ = ["RouteIndex"]
