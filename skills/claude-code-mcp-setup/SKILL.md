---
name: claude-code-mcp-setup
description: Add and configure MCP (Model Context Protocol) servers in Claude Code. Use when adding new MCP servers, configuring remote MCP, setting up OAuth MCP servers, troubleshooting MCP connections, or running /mcp diagnostics. Covers stdio, HTTP, and SSE transport types.
---

# Claude Code MCP Setup

## Purpose

Guide for adding and configuring MCP (Model Context Protocol) servers in Claude Code CLI.

## When to Use

- Adding a new MCP server to Claude Code
- Configuring remote MCP servers (HTTP/SSE)
- Troubleshooting MCP connection failures
- Understanding MCP transport types
- Setting up OAuth-authenticated MCP servers

## Quick Reference

### CLI Commands

```bash
# Add local stdio MCP server
claude mcp add <name> <command> [args...]

# Add remote HTTP MCP server (supports OAuth)
claude mcp add --transport http <name> <url>

# Add remote SSE MCP server
claude mcp add --transport sse <name> <url>

# Add with environment variables
claude mcp add <name> -e API_KEY=xxx -- <command> [args...]

# Add with custom headers
claude mcp add --transport http <name> <url> --header "Authorization: Bearer xxx"

# List configured servers
claude mcp list

# Remove a server
claude mcp remove <name>
```

### Transport Types

| Type | Use Case | Example |
|------|----------|---------|
| `stdio` | Local NPM packages, scripts | `claude mcp add my-server npx @org/mcp-server` |
| `http` | Remote servers with OAuth | `claude mcp add --transport http monday https://mcp.monday.com/mcp` |
| `sse` | Server-Sent Events servers | `claude mcp add --transport sse name https://example.com/sse` |

## Common MCP Server Examples

### monday.com (Remote HTTP with OAuth)

```bash
claude mcp add --transport http monday https://mcp.monday.com/mcp
```

After adding, restart Claude Code and run `/mcp`. First connection will prompt OAuth authorization in browser.

### GitHub (Local with Token)

```bash
claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx -- npx @modelcontextprotocol/server-github
```

### Filesystem (Local)

```bash
claude mcp add filesystem npx @modelcontextprotocol/server-filesystem /path/to/directory
```

### Custom Local Server

```bash
claude mcp add my-server node /path/to/server.js
```

## Configuration Files

MCP servers are stored in:

- **User config**: `~/.claude.json` (global)
- **Project config**: `.mcp.json` (per-project, legacy)

### Manual Configuration (if needed)

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["@org/mcp-package"],
      "env": {
        "API_KEY": "your-key"
      }
    }
  }
}
```

For remote servers:

```json
{
  "mcpServers": {
    "remote-server": {
      "type": "url",
      "url": "https://example.com/mcp"
    }
  }
}
```

## Troubleshooting

### Check MCP Status

```bash
# Inside Claude Code
/mcp

# Detailed diagnostics
/doctor
```

### Common Issues

**"Does not adhere to MCP server configuration schema"**
- Use `claude mcp add` CLI command instead of manual JSON editing
- Ensure correct transport type for remote servers

**"Failed to reconnect"**
- Check network connectivity
- Verify OAuth authorization completed
- Try removing and re-adding: `claude mcp remove <name> && claude mcp add ...`

**OAuth not prompting**
- Restart Claude Code after adding server
- Run `/mcp` to trigger connection
- Check browser for blocked popups

**Environment variable errors**
- Use `-e VAR=value` flag when adding
- Or set in shell before running Claude Code

### Verify Configuration

```bash
# Check what was added
cat ~/.claude.json | jq '.mcpServers'

# Validate JSON syntax
jq . ~/.claude.json
```

## Resources

- [Claude Code MCP Docs](https://code.claude.com/docs/en/mcp)
- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP Server Registry](https://github.com/modelcontextprotocol/servers)
