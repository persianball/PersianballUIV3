#!/usr/bin/env python3
"""Make Flutter's generated service worker work under a sub-path.

`flutter build web` emits flutter_service_worker.js that keys every request
relative to the *origin* (`self.location.origin`). GitHub Pages serves this app
under /<repo>/, so every key comes out as "PersianballUIV3/main.dart.js" and
never matches the resource list ("main.dart.js"). The effect, measured in real
Chrome with the network cut:

  * fetch     - nothing is ever served from cache, so offline launch fails;
  * activate  - on every deploy each cached file looks unknown and is deleted;
  * index     - the offline fallback only tries the exact navigation URL, which
                is not cached after the first visit.

This rewrites those spots to key relative to the worker's own directory, and
falls back to the cached index.html. Every edit asserts its anchor is present,
so a Flutter upgrade that changes the template fails the build loudly instead
of silently shipping a worker that caches nothing.

Usage: python3 tool/patch_service_worker.py build/web/flutter_service_worker.js
"""
import sys

MARK = "[persianshop-subpath-patch]"

PREAMBLE = f"""'use strict';
// {MARK} Keys are taken relative to this worker's directory, not the origin,
// so the cache works when the app is served under a sub-path (e.g. /<repo>/).
// Applied by tool/patch_service_worker.py after `flutter build web`.
const SCOPE_BASE = new URL('./', self.location).href;
"""

# (anchor, replacement, expected occurrences)
EDITS = [
    ("'use strict';\n", PREAMBLE, 1),
    # fetch: ignore anything outside our directory, key the rest relative to it
    ("  var key = event.request.url.substring(origin.length + 1);",
     "  if (!event.request.url.startsWith(SCOPE_BASE)) {\n"
     "    return;\n"
     "  }\n"
     "  var key = event.request.url.substring(SCOPE_BASE.length);", 1),
    # activate + downloadOffline: cached-entry keys. Must run after the fetch edit
    # above, whose anchor contains this one as a substring.
    ("request.url.substring(origin.length + 1)",
     "request.url.substring(SCOPE_BASE.length)", 2),
    ("if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {",
     "if (key == '' || key.startsWith('#')) {", 1),
    # the page itself: if this exact URL was never cached, serve the cached shell
    ("return cache.match(event.request).then((response) => {\n          if (response != null) {",
     "return cache.match(event.request)\n"
     "          .then((response) => response || cache.match('index.html'))\n"
     "          .then((response) => {\n          if (response != null) {", 1),
]


def main(path: str) -> int:
    src = open(path, encoding="utf-8").read()
    if MARK in src:
        print(f"{path}: already patched")
        return 0
    for anchor, replacement, expected in EDITS:
        found = src.count(anchor)
        if found != expected:
            print(f"ERROR: expected {expected}x anchor, found {found}x:\n  {anchor!r}\n"
                  "Flutter's service worker template changed; update this patch.",
                  file=sys.stderr)
            return 1
        src = src.replace(anchor, replacement)
    open(path, "w", encoding="utf-8").write(src)
    print(f"{path}: patched ({len(EDITS)} edits)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "build/web/flutter_service_worker.js"))
