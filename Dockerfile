# استخدام نسخة بايثون خفيفة وسريعة (نسخة 2026)
FROM python:3.12-slim-bookworm

# تثبيت FFmpeg (العمود الفقري للتحميل) وأدوات النظام
# هذه الخطوة تجعل السيرفر قادراً على دمج فيديوهات 4K
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# إعداد مجلد العمل داخل السيرفر
WORKDIR /app

# نسخ ملف المكتبات وتثبيتها
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# نسخ باقي ملفات السيرفر (main.py)
COPY . .

# فتح البورت 8000
EXPOSE 8000

# أمر التشغيل باستخدام Gunicorn مع Uvicorn لأقصى أداء
# workers = عدد الأنوية (أنت تملك 16، سنستخدم 8 للويب و8 للمعالجة)
CMD ["gunicorn", "main:app", "--workers", "8", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
