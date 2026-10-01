# Xdebug with DDEV

Enabling Xdebug and connecting an IDE, moved from SKILL.md.

## Debugging with Xdebug

```bash
# Enable Xdebug
ddev xdebug on

# Run your debugger in IDE (PHPStorm, VSCode)
# Set breakpoints and refresh page

# Disable when done (improves performance)
ddev xdebug off

# Check Xdebug status
ddev xdebug status
```

**VSCode launch.json**:
```json
{
  "name": "Listen for Xdebug",
  "type": "php",
  "request": "launch",
  "port": 9003,
  "pathMappings": {
    "/var/www/html": "${workspaceFolder}"
  }
}
```
