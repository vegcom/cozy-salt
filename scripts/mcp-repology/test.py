#!/usr/bin/env python3
"""Quick test for repology resolver - run standalone"""

from server import resolve_package, query_repology

test_packages = ["vim", "fd", "ripgrep", "htop", "nonexistent-pkg-12345"]

print("Testing package resolution:\n")
for pkg in test_packages:
    result = resolve_package(pkg)
    print(f"{pkg}:")
    print(f"  source: {result['source']}")
    for distro, name in result['mapping'].items():
        print(f"  {distro}: {name}")
    print()
