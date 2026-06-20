FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    git \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      python3.12 \
      python3.12-venv \
    && python3.12 -m ensurepip --upgrade \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && rm -rf /var/lib/apt/lists/*

COPY install/requirements.txt /tmp/requirements.txt
COPY install/requirements-base.txt /tmp/requirements-base.txt
RUN python3.12 -m pip install -r /tmp/requirements.txt

# Install FFmpeg with CUDA/NVDEC support
COPY scripts/install_ffmpeg_cuda.py /tmp/install_ffmpeg_cuda.py
RUN python3.12 /tmp/install_ffmpeg_cuda.py --prefix /usr/local && rm /tmp/install_ffmpeg_cuda.py

COPY dist/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl /tmp/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl
RUN python3.12 -m pip install /tmp/ai_processing-0.0.0-cp312-cp312-linux_x86_64.whl

WORKDIR /app
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=5 \
  CMD curl -fsS http://localhost:8000/health || exit 1

CMD ["python3.12", "server.py"]
