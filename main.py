# ==============================================================================
# 🚀 PROJECT: LIQUID GLASS ENGINE (ENTERPRISE EDITION)
# 📂 FILE: backend/main.py
# 👤 AUTHOR: GEMINI PRO (INTELLIGENT ARCHITECT)
# ⚙️ SPECS: OPTIMIZED FOR 16 CORES / HIGH-THROUGHPUT / ANTI-BOT BYPASS
# ==============================================================================

import os
import sys
import time
import json
import logging
import asyncio
from typing import List, Optional, Dict, Any
from enum import Enum
from concurrent.futures import ThreadPoolExecutor

# ------------------------------------------------------------------------------
# 1. Dependency Initialization & Safety Checks
# ------------------------------------------------------------------------------
try:
    import uvicorn
    import yt_dlp
    from fastapi import FastAPI, HTTPException, Request
    from fastapi.middleware.cors import CORSMiddleware
    from pydantic import BaseModel, Field
    # psutil is optional but recommended for server monitoring
    try:
        import psutil
    except ImportError:
        psutil = None
except ImportError as e:
    print(f"❌ [CRITICAL ERROR] Missing Library: {e}")
    print("👉 Run: pip install fastapi uvicorn yt-dlp pydantic psutil")
    sys.exit(1)

# ------------------------------------------------------------------------------
# 2. Server Configuration (The Brain)
# ------------------------------------------------------------------------------
API_VERSION = "v1"
HOST = "0.0.0.0"
PORT = 8080

# 🔥 THREADING OPTIMIZATION:
# Uses (CPU_COUNT * 2) workers to maximize throughput on your 16-Core Server.
CPU_CORES = os.cpu_count() or 4
MAX_WORKERS = CPU_CORES * 2 

# Logging Configuration (Professional Audit Trail)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] ⚡ %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("LiquidEngine")

# ------------------------------------------------------------------------------
# 3. Data Models (Strict Validation Layer)
# ------------------------------------------------------------------------------
class RequestModel(BaseModel):
    """The expected data packet from the mobile app."""
    url: str
    include_audio: bool = True

class FormatModel(BaseModel):
    """Blueprint for a single download option."""
    resolution: str
    ext: str
    url: str
    filesize: Optional[str] = "Unknown"
    note: Optional[str] = ""

class ResponseModel(BaseModel):
    """The clean, structured response sent back to the app."""
    title: str
    thumbnail: str
    duration: int
    formats: List[FormatModel]
    server_time: float

# ------------------------------------------------------------------------------
# 4. The Core Engine (Anti-Bot & Extraction Logic)
# ------------------------------------------------------------------------------
class LiquidEngine:
    """
    The heart of the application. Encapsulates yt-dlp logic 
    with advanced spoofing to bypass YouTube blocking.
    """
    
    def __init__(self):
        # 🛡️ STEALTH MODE CONFIGURATION
        self.ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'format': 'best', # We fetch best, then extract all formats manually
            'extract_flat': False,
            
            # 🚀 PERFORMANCE SETTINGS
            'socket_timeout': 15,
            'retries': 5,
            'nocheckcertificate': True,
            
            # 🕵️ ANTI-BOT & GEO-BYPASS TACTICS
            'geo_bypass': True,
            'force_ipv4': True, # Crucial for Cloud Servers (Fly.io/AWS)
            'source_address': '0.0.0.0',
            
            # 🤖 CLIENT SPOOFING (The key to fixing 403 Errors)
            # Pretends to be a real Android device using the official API
            'extractor_args': {
                'youtube': {
                    'player_client': ['android', 'web'],
                    'skip': ['hls', 'dash'] # Skip streaming protocols, focus on direct files
                }
            }
        }

    def _format_size(self, bytes_size):
        if not bytes_size: return "Unknown"
        for unit in ['B', 'KB', 'MB', 'GB']:
            if bytes_size < 1024:
                return f"{bytes_size:.2f} {unit}"
            bytes_size /= 1024
        return f"{bytes_size:.2f} TB"

    def process(self, url: str, include_audio: bool) -> Dict:
        """Synchronous extraction logic (run in thread pool)."""
        start_time = time.time()
        
        try:
            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                # 1. Extract Info
                info = ydl.extract_info(url, download=False)
                
                # 2. Filter & Clean Formats
                valid_formats = []
                unique_qualities = set()

                raw_formats = info.get('formats', [])
                # Reverse to get best quality first usually
                for f in reversed(raw_formats):
                    video_url = f.get('url')
                    if not video_url: continue # Skip if no direct link
                    
                    # Logic to identify resolution
                    height = f.get('height')
                    res = f"{height}p" if height else "Audio Only"
                    ext = f.get('ext', 'mp4')
                    
                    # Deduplication key
                    fid = f"{res}-{ext}"
                    if fid in unique_qualities: continue
                    unique_qualities.add(fid)

                    # Build the object
                    valid_formats.append({
                        "resolution": res,
                        "ext": ext,
                        "url": video_url,
                        "filesize": self._format_size(f.get('filesize')),
                        "note": f.get('format_note', '')
                    })

                # 3. Construct Final Response
                return {
                    "title": info.get('title', 'Unknown Title'),
                    "thumbnail": info.get('thumbnail', ''),
                    "duration": info.get('duration', 0),
                    "formats": valid_formats,
                    "server_time": round(time.time() - start_time, 3)
                }

        except Exception as e:
            logger.error(f"Extraction Failed: {str(e)}")
            # Re-raise to be caught by FastAPI handler
            raise RuntimeError(str(e))

# ------------------------------------------------------------------------------
# 5. FastAPI Application Lifecycle
# ------------------------------------------------------------------------------
app = FastAPI(
    title="Liquid Glass Snap Engine",
    description="Enterprise Backend for High-Fidelity Media Extraction",
    version="2.0.0 Pro"
)

# 🌐 CORS: ALLOW ALL (Crucial for Mobile Apps)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Engine & Thread Pool
engine = LiquidEngine()
executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)

# ------------------------------------------------------------------------------
# 6. API Endpoints
# ------------------------------------------------------------------------------

@app.get("/", tags=["System"])
async def health_check():
    """Ping endpoint for Fly.io health checks."""
    process = psutil.Process(os.getpid()) if psutil else None
    usage = process.memory_info().rss / 1024 / 1024 if process else 0
    
    return {
        "status": "operational",
        "engine": "Liquid Glass v2.0",
        "cores_utilized": MAX_WORKERS,
        "memory_usage_mb": round(usage, 2)
    }

@app.post(f"/api/{API_VERSION}/extract", response_model=ResponseModel, tags=["Core"])
async def extract_endpoint(req: RequestModel):
    """
    Non-blocking endpoint. 
    Offloads the heavy yt-dlp work to a separate thread.
    """
    logger.info(f"📥 REQUEST: {req.url}")
    
    # Validation
    if not req.url.strip():
        raise HTTPException(status_code=400, detail="URL cannot be empty")

    try:
        # ⚡ RUN IN THREAD POOL (Async Magic)
        # This prevents the server from freezing while processing
        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(
            executor, 
            engine.process, 
            req.url, 
            req.include_audio
        )
        
        logger.info(f"✅ SUCCESS: '{result['title'][:30]}...' ({result['server_time']}s)")
        return result

    except RuntimeError as e:
        error_msg = str(e)
        logger.error(f"❌ ENGINE ERROR: {error_msg}")
        
        # Smart Error Mapping
        if "Sign in" in error_msg or "private" in error_msg.lower():
            raise HTTPException(status_code=422, detail="Video is private or age-restricted.")
        elif "bot" in error_msg.lower():
            raise HTTPException(status_code=429, detail="Server is currently rate-limited by YouTube.")
        else:
            raise HTTPException(status_code=400, detail=f"Could not process video: {error_msg}")

    except Exception as e:
        logger.critical(f"🔥 SYSTEM CRASH: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

# ------------------------------------------------------------------------------
# 7. Entry Point
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    print(f"\n🚀 STARTING LIQUID GLASS ENGINE [ENTERPRISE]")
    print(f"💎 CORES: {CPU_CORES} | WORKERS: {MAX_WORKERS}")
    print(f"📡 LISTENING: http://{HOST}:{PORT}\n")
    
    uvicorn.run(app, host=HOST, port=PORT)
