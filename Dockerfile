# Stage 1: build frontend
FROM oven/bun:1 AS frontend-builder
WORKDIR /build
COPY frontend/package.json frontend/bun.lock ./
RUN bun install --frozen-lockfile
COPY frontend/ .
RUN bun run build

# Stage 2: Python runtime
FROM python:3.14-slim
LABEL maintainer="Sean-Michael seanm.riesterer@gmail.com"
WORKDIR /code

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-cache

COPY app/ app/
COPY --from=frontend-builder /build/dist/ frontend/dist/

RUN useradd --create-home appuser
USER appuser

ENV PORT=8000
EXPOSE ${PORT}

CMD ["sh", "-c", "uv run uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
