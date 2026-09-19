# spinCD

Keeping track of my CD collection!

There are two front ends over the same collection:

- **macOS app** (`macos/`) — native SwiftUI, its own local SQLite database, all
  album scans bundled in. Nothing to run alongside it.
- **Web app** (`app/` + `frontend/`) — the original FastAPI + React version.

## The macOS app

```zsh
% cd macos
% ./scripts/build_app.sh        # universal build -> macos/dist/spinCD.app
% open dist/spinCD.app
```

The database lives at `~/Library/Application Support/spinCD/spincd.db` and is
seeded with the curated collection the first time the app launches. For
day-to-day work, `swift run spinCD` and `swift test` are quicker.

## Web development

### 1. [Install uv](https://docs.astral.sh/uv/getting-started/installation/)

With `uv` installed and the repository cloned, sync the dependencies: 

```bash
uv sync
```

To start the development server locally with reloading:

```zsh
% uv run fastapi dev
```

### 2. [Install Bun](https://bun.com/docs/installation) 

Install frontend dependencies:

```zsh
% bun install
```

Now we can start the frontend development server using `Vite` this provides a local host of the frontend with hot reloads.

```bash
% cd frontend
% bun run dev     
```