from contextlib import asynccontextmanager
from pathlib import Path
import sys

_project_root = Path(__file__).resolve().parent.parent.parent
if str(_project_root) not in sys.path:
    sys.path.insert(0, str(_project_root))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from src.api.routers import (
    agent_config,
    chat,
    co_writer,
    dashboard,
    embedding_provider,
    guide,
    ideagen,
    knowledge,
    llm_provider,
    notebook,
    question,
    research,
    settings,
    solve,
    system,
)
from src.logging import get_logger
from src.services.config import get_data_dir, get_user_dir

logger = get_logger("API")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifecycle management
    Gracefully handle startup and shutdown events, avoid CancelledError
    """
    logger.info("Application startup")
    yield
    logger.info("Application shutdown")


app = FastAPI(title="DeepTutor API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific frontend origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount user directory as static root for generated artifacts
# This allows frontend to access generated artifacts (images, PDFs, etc.)
# URL: /api/outputs/solve/solve_xxx/artifacts/image.png
# Physical Path: data/user/solve/solve_xxx/artifacts/image.png
# Uses DEEPTUTOR_DATA_DIR env var if set (for containerized deployments)
user_dir = get_user_dir()

# Initialize user directories on startup
try:
    from src.services.setup import init_user_directories

    init_user_directories()
except Exception:
    # Fallback: just create the main directory if it doesn't exist
    if not user_dir.exists():
        user_dir.mkdir(parents=True)

app.mount("/api/outputs", StaticFiles(directory=str(user_dir)), name="outputs")

app.include_router(solve.router, prefix="/api/v1", tags=["solve"])
app.include_router(chat.router, prefix="/api/v1", tags=["chat"])
app.include_router(question.router, prefix="/api/v1/question", tags=["question"])
app.include_router(research.router, prefix="/api/v1/research", tags=["research"])
app.include_router(knowledge.router, prefix="/api/v1/knowledge", tags=["knowledge"])
app.include_router(dashboard.router, prefix="/api/v1/dashboard", tags=["dashboard"])
app.include_router(co_writer.router, prefix="/api/v1/co_writer", tags=["co_writer"])
app.include_router(notebook.router, prefix="/api/v1/notebook", tags=["notebook"])
app.include_router(guide.router, prefix="/api/v1/guide", tags=["guide"])
app.include_router(ideagen.router, prefix="/api/v1/ideagen", tags=["ideagen"])
app.include_router(settings.router, prefix="/api/v1/settings", tags=["settings"])
app.include_router(system.router, prefix="/api/v1/system", tags=["system"])
app.include_router(llm_provider.router, prefix="/api/v1/config/llm", tags=["config"])
app.include_router(embedding_provider.router, prefix="/api/v1/config/embedding", tags=["config"])
app.include_router(agent_config.router, prefix="/api/v1/config", tags=["config"])


@app.get("/")
async def root():
    return {"message": "Welcome to DeepTutor API"}


if __name__ == "__main__":
    import uvicorn

    # Get port from configuration
    from src.services.setup import get_backend_port

    backend_port = get_backend_port(_project_root)

    # Configure reload_excludes with absolute paths to properly exclude directories
    venv_dir = _project_root / "venv"
    data_dir = get_data_dir()
    reload_excludes = [
        str(d)
        for d in [
            venv_dir,
            _project_root / ".venv",
            data_dir,
            _project_root / "web" / "node_modules",
            _project_root / "web" / ".next",
            _project_root / ".git",
        ]
        if d.exists()
    ]

    uvicorn.run(
        "api.main:app",
        host="0.0.0.0",
        port=backend_port,
        reload=True,
        reload_excludes=reload_excludes,
    )
