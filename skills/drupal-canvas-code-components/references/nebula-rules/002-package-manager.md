# Package manager

Detect the package manager by checking for lock files in the project root:

- `package-lock.json` → npm (`npm run`, `npx`)
- `yarn.lock` → yarn (`yarn`, `yarn dlx`)
- `pnpm-lock.yaml` → pnpm (`pnpm`, `pnpm dlx`)
- `bun.lockb` → bun (`bun run`, `bunx`)

Use the detected package manager for all commands in these instructions.
