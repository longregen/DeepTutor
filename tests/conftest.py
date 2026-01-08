"""
Pytest configuration and fixtures for DeepTutor tests.
"""

from pathlib import Path
import sys

# Add project root to path for imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
