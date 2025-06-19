#
# Base
#
FROM ghcr.io/astral-sh/uv:alpine3.21 AS base
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHON_VERSION=3.10

ENV UV_CACHE_DIR=/var/cache/uv
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_FROZEN=1
ENV UV_NO_EDITABLE=1

# Install Python
RUN uv python install ${PYTHON_VERSION}

# Project directory
WORKDIR /app

#
# Builder
#
FROM base AS builder

# Create the virtual environment
RUN uv venv --relocatable --python ${PYTHON_VERSION}

# Install dependencies
RUN --mount=type=cache,target=/var/cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
        uv sync --no-install-project --no-dev

# Copy the source code and build it
COPY ./ ./

RUN --mount=type=cache,target=/var/cache/uv \
  uv sync --no-dev

#
# Runtime
#
FROM base
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

ENV MCP_ALLOW_SYSTEM_ACCESS=0
ENV MCP_DIR=/workspace

# Copy the virtual environment from the builder stage
# This includes the project binary.
COPY --link --from=builder /app/.venv ./.venv

ENTRYPOINT /app/.venv/bin/mcp-python-interpreter --dir ${MCP_DIR}