# MCP Servers

MCP servers used by this project are configured in `.mcp.json`.

## shadcn

Provides Claude with access to the shadcn/ui component registry for component scaffolding and documentation.

**Pinned version:** `shadcn@3.8.5` (stdio transport — no remote connection)

**Upstream source:** https://ui.shadcn.com/mcp/claude-code

To check for updates and manually bump the version in `.mcp.json`:

```bash
npm view shadcn version
```
