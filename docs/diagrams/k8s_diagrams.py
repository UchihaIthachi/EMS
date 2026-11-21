#!/usr/bin/env python3
"""Rebuild the icon diagrams in docs/img/.

    pip install diagrams playwright && python3 -m playwright install chromium
    python3 docs/diagrams/k8s_diagrams.py

Icons come from the `diagrams` package (official Kubernetes and vendor icons); the layout is
hand-placed on a grid by gridiagram.py, so lines stay straight and aligned.
Each script writes an .svg and a 2x .png next to the README's images.
"""
import os, runpy
HERE = os.path.dirname(os.path.abspath(__file__))
for script in ("k8s_arch.py", "k8s_objects.py", "k8s_platform.py"):
    runpy.run_path(os.path.join(HERE, script), run_name="__main__")
