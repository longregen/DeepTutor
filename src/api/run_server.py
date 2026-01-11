#!/usr/bin/env python
"""
Uvicorn Server Startup Script
Uses Python API instead of command line to avoid Windows path parsing issues.
"""

import os
import sys

# Force unbuffered output
os.environ["PYTHONUNBUFFERED"] = "1"
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(line_buffering=True)
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(line_buffering=True)

from pathlib import Path

import uvicorn

if __name__ == "__main__":
    _project_root = Path(__file__).resolve().parent.parent.parent
    if str(_project_root) not in sys.path:
        sys.path.insert(0, str(_project_root))

    # Change to project root to ensure correct module imports
    os.chdir(str(_project_root))

    # Get port from configuration
    from src.services.config import get_data_dir
    from src.services.setup import get_backend_port

    backend_port = get_backend_port(_project_root)

    # Configure reload_excludes to skip directories that shouldn't trigger reloads
    # Use absolute paths to ensure they're properly resolved
    reload_excludes = [
        str(_project_root / "venv"),  # Virtual environment
        str(_project_root / ".venv"),  # Virtual environment (alternative name)
        str(get_data_dir()),  # Data directory (respects DEEPTUTOR_DATA_DIR env var)
        str(_project_root / "node_modules"),  # Node modules (if any at root)
        str(_project_root / "web" / "node_modules"),  # Web node modules
        str(_project_root / "web" / ".next"),  # Next.js build
        str(_project_root / ".git"),  # Git directory
        str(_project_root / "scripts"),  # Scripts directory - don't reload on launcher changes
    ]

    # Filter out non-existent directories to avoid warnings
    reload_excludes = [d for d in reload_excludes if Path(d).exists()]

    # Start uvicorn server with reload enabled
    uvicorn.run(
        "src.api.main:app",
        host="0.0.0.0",
        port=backend_port,
        reload=True,
        reload_excludes=reload_excludes,
        log_level="info",
    )
