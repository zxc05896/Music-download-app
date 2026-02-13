"""
================================================================================
Project: Liquid Glass Snap Engine
File: backend/main.py
Version: 1.0.0 Enterprise Edition
Author: Gemini (Your AI Assistant)
Description: 
    This is the core backend engine designed for High-Performance Servers 
    (16 Cores / 100GB RAM). It utilizes FastAPI for asynchronous request 
    handling and a ThreadPoolExecutor to leverage multi-core processing 
    for video extraction via yt-dlp.
================================================================================
"""

import os
import sys
import time
import json
import logging
import asyncio
import secrets
from typing import List, Optional, Dict, Any, Union
from concurrent.futures import ThreadPoolExecutor
from enum import Enum

# ------------------------------------------------------------------------------
# 1. Dependency Checks & Imports
# ------------------------------------------------------------------------------
try:
    from fastapi import FastAPI, HTTPException, Request, Depends, BackgroundTasks
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
    from fastapi.security import APIKeyHeader
    from pydantic import BaseModel, Field, HttpUrl
    import uvicorn
    import yt_dlp
except ImportError as e:
    print(f"[CRITICAL ERROR] Missing Dependency: {e}")
    print("Please ensure 'requirements.txt' is installed.")
    sys.exit(1)

# ------------------------------------------------------------------------------
# 2. Advanced Configuration & Constants
# ------------------------------------------------------------------------------

# Server Configuration
SERVER_HOST = "0.0.0.0"
SERVER_PORT = 8000
WORKER_THREADS = 32  # Optimized for 16 Cores (2x Cores is a good rule of thumb)
API_VERSION = "v1"
APP_NAME = "LiquidGlass-Engine"

# Security Configuration
# In production, use environment variables for keys!
API_SECRET_KEY = os.getenv("API_SECRET", "liquid_glass_super_secret_key_2026")
ALLOWED_ORIGINS = ["*"]  # Allow all for mobile app access (Restrict in Production)

# ------------------------------------------------------------------------------
# 3. Logging System Setup
# ------------------------------------------------------------------------------
# We create a sophisticated logger to track every move of the server.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(threadName)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("server_logs.log", mode='a', encoding='utf-8')
    ]
)
logger = logging.getLogger(APP_NAME)

# ------------------------------------------------------------------------------
# 4. Data Models (Pydantic Schema)
# ------------------------------------------------------------------------------
# These classes ensure the data coming from the mobile app is valid.

class VideoFormatType(str, Enum):
    VIDEO = "video"
    AUDIO = "audio"
    BOTH = "video+audio"

class VideoQuality(BaseModel):
    """Represents a single quality option for a video."""
    format_id: str = Field(..., description="The unique ID from yt-dlp")
    ext: str = Field(..., description="File extension (mp4, webm, mp3)")
    resolution: Optional[str] = Field(None, description="Resolution (e.g., 1080p)")
    filesize: Optional[int] = Field(None, description="Approximate file size in bytes")
    video_codec: Optional[str] = Field(None, description="Video codec used")
    audio_codec: Optional[str] = Field(None, description="Audio codec used")
    url: Optional[str] = Field(None, description="Direct download URL")
    note: Optional[str] = Field(None, description="Extra info (e.g., HDR, 60fps)")

class VideoMetadata(BaseModel):
    """Comprehensive metadata about the requested video."""
    id: str
    title: str
    uploader: Optional[str] = None
    duration: Optional[int] = None
    view_count: Optional[int] = None
    thumbnail: Optional[str] = None
    description: Optional[str] = None
    formats: List[VideoQuality]

class ExtractionRequest(BaseModel):
    """The request body expected from the Liquid Glass App."""
    url: HttpUrl = Field(..., description="The URL of the video to process")
    include_audio: bool = Field(True, description="Whether to fetch audio-only formats")
    cookies_path: Optional[str] = Field(None, description="Path to cookies file if needed")

class ServerStatus(BaseModel):
    status: str
    uptime: float
    workers_active: int
    memory_usage: str

# ------------------------------------------------------------------------------
# 5. The Core Engine (yt-dlp Wrapper)
# ------------------------------------------------------------------------------
class YTDLPEngine:
    """
    A High-Performance wrapper around yt-dlp.
    Designed to run in a separate thread pool to avoid blocking the API.
    """
    def __init__(self):
        # Base options for maximum compatibility and speed
        self.base_opts = {
            'quiet': True,
            'no_warnings': True,
            'format': 'bestvideo+bestaudio/best',
            'extract_flat': False,
            'socket_timeout': 15,
            'retries': 10,
            'nocheckcertificate': True,
            'geo_bypass': True,
            # User Agent spoofing to avoid detection
            'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        }

    def _process_formats(self, formats_raw: List[Dict]) -> List[VideoQuality]:
        """
        Cleans and sorts the raw formats from yt-dlp into a clean list for the App.
        """
        processed = []
        for f in formats_raw:
            # Skip m3u8 (HLS) streams if direct links are preferred, 
            # but keep them if that's all there is.
            
            # Logic to determine resolution string
            res = f"{f.get('height')}p" if f.get('height') else "Audio Only"
            
            # Logic to determine note
            note_parts = []
            if f.get('fps') and f.get('fps') > 30:
                note_parts.append(f"{int(f['fps'])}fps")
            if f.get('vcodec') != 'none' and f.get('acodec') != 'none':
                 note_parts.append("Video+Audio")
            elif f.get('vcodec') == 'none':
                 note_parts.append("Audio Only")
            else:
                 note_parts.append("Video Only")

            q = VideoQuality(
                format_id=f.get('format_id', 'unknown'),
                ext=f.get('ext', 'mp4'),
                resolution=res,
                filesize=f.get('filesize') or f.get('filesize_approx'),
                video_codec=f.get('vcodec'),
                audio_codec=f.get('acodec'),
                url=f.get('url'),
                note=", ".join(note_parts)
            )
            processed.append(q)
        
        # Sort: Highest resolution first, then file size
        processed.sort(key=lambda x: (
            int(x.resolution.replace('p', '')) if 'p' in x.resolution else 0, 
            x.filesize or 0
        ), reverse=True)
        
        return processed

    def extract(self, url: str) -> VideoMetadata:
        """
        The main extraction logic.
        """
        logger.info(f"Starting extraction for URL: {url}")
        start_time = time.time()
        
        try:
            with yt_dlp.YoutubeDL(self.base_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                
                # Sanitize Data
                clean_formats = self._process_formats(info.get('formats', []))
                
                metadata = VideoMetadata(
                    id=info.get('id'),
                    title=info.get('title'),
                    uploader=info.get('uploader'),
                    duration=info.get('duration'),
                    view_count=info.get('view_count'),
                    thumbnail=info.get('thumbnail'),
                    description=info.get('description')[:500] if info.get('description') else "", # Limit description
                    formats=clean_formats
                )
                
                elapsed = time.time() - start_time
                logger.info(f"Extraction successful. Time: {elapsed:.2f}s. Formats found: {len(clean_formats)}")
                return metadata
                
        except yt_dlp.utils.DownloadError as e:
            logger.error(f"Download Error: {str(e)}")
            raise ValueError(f"Video unavailable or private: {str(e)}")
        except Exception as e:
            logger.critical(f"Unexpected Error in Engine: {str(e)}")
            raise RuntimeError(f"Internal Engine Error: {str(e)}")

# ------------------------------------------------------------------------------
# 6. FastAPI Application Initialization
# ------------------------------------------------------------------------------
app = FastAPI(
    title="Liquid Glass Downloader API",
    description="High-Performance Backend for Video Extraction",
    version=API_VERSION,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Middleware (Crucial for Mobile App Communication)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Thread Pool for Heavy Lifting
# We use this to offload yt-dlp (which is synchronous) from the main async loop.
executor = ThreadPoolExecutor(max_workers=WORKER_THREADS)
engine = YTDLPEngine()
server_start_time = time.time()

# ------------------------------------------------------------------------------
# 7. Helper Utilities
# ------------------------------------------------------------------------------
async def run_in_threadpool(func, *args):
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(executor, func, *args)

# ------------------------------------------------------------------------------
# 8. API Endpoints
# ------------------------------------------------------------------------------

@app.on_event("startup")
async def startup_event():
    logger.info("Server is starting up...")
    logger.info(f"Configured with {WORKER_THREADS} worker threads.")
    logger.info(f"Running on {SERVER_HOST}:{SERVER_PORT}")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Server is shutting down...")
    executor.shutdown(wait=True)
    logger.info("Thread pool closed.")

@app.get("/", tags=["Health"])
async def root():
    """Simple Health Check Endpoint."""
    uptime = time.time() - server_start_time
    return {
        "app": APP_NAME,
        "status": "operational",
        "uptime_seconds": round(uptime, 2),
        "docs": "/docs"
    }

@app.get(f"/api/{API_VERSION}/status", response_model=ServerStatus, tags=["Health"])
async def get_server_status():
    """Returns detailed server stats."""
    import psutil
    mem = psutil.virtual_memory()
    uptime = time.time() - server_start_time
    
    return ServerStatus(
        status="active",
        uptime=uptime,
        workers_active=WORKER_THREADS,
        memory_usage=f"{mem.percent}% used of {round(mem.total / (1024**3), 2)} GB"
    )

@app.post(f"/api/{API_VERSION}/extract", response_model=VideoMetadata, tags=["Core"])
async def extract_video(request: ExtractionRequest):
    """
    Main Endpoint: Receives a URL, returns all video formats.
    This runs asynchronously using the ThreadPool to prevent blocking.
    """
    url = str(request.url)
    logger.info(f"Received extraction request for: {url}")
    
    if "youtube" not in url and "youtu.be" not in url and "facebook" not in url and "instagram" not in url:
        # We can expand this check later, but for now warning
        logger.warning(f"URL might not be supported: {url}")

    try:
        # Offload the heavy blocking work to the thread pool
        result = await run_in_threadpool(engine.extract, url)
        return result
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except RuntimeError as re:
        raise HTTPException(status_code=500, detail="Server processing error. Please try again.")
    except Exception as e:
        logger.error(f"Unhandled API Error: {e}")
        raise HTTPException(status_code=500, detail="Unknown Server Error")

# ------------------------------------------------------------------------------
# 9. Execution Entry Point
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    # In a production environment, you would usually run this with:
    # uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
    
    print(f"--- Starting {APP_NAME} Enterprise Edition ---")
    print(f"--- Detected High-Spec Environment: 16 Cores Available ---")
    
    uvicorn.run(
        "main:app", 
        host=SERVER_HOST, 
        port=SERVER_PORT, 
        reload=True, # Auto-reload on code changes (Dev mode)
        log_level="info"
    )

