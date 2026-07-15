# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

# Install the project into /app
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Install the project's dependencies using the lockfile and settings
COPY pyproject.toml uv.lock /app/
RUN --mount=type=cache,id=s/53926d41-19d4-418f-baf9-bda9be9eb322-/root/.cache/uv,target=/root/.cache/uv uv sync --frozen --no-install-project --no-dev --no-editable

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
ADD src /app/src
RUN --mount=type=cache,id=s/53926d41-19d4-418f-baf9-bda9be9eb322-/root/.cache/uv,target=/root/.cache/uv uv sync --frozen --no-dev --no-editable

FROM python:3.12-slim-bookworm

WORKDIR /app

COPY --from=uv /app/.venv /app/.venv

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# DUFFEL_API_KEY_LIVE is required at runtime (see src/flights/config/api.py) - set it on the
# host/platform (e.g. Railway service variables), not baked in here.

# This image is only used for network deployment (e.g. Railway) - default to Streamable HTTP
# (see server.py). Package installs run via `uv run flights-mcp` (Claude Desktop, Smithery)
# still default to stdio unless MCP_TRANSPORT is set, so this only affects this image.
ENV MCP_TRANSPORT=streamable-http
EXPOSE 8080

# Start the MCP server
ENTRYPOINT ["flights-mcp"]
