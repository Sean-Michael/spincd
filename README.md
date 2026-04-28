# spinCD

Keeping track of my CD collection!

## Development

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