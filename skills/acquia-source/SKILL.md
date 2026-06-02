---
name: acquia-source
description: Connect to an Acquia Source ("Source powered by Drupal CMS") site — its JSON:API and MCP endpoints, OAuth2 auth, the @drupal-canvas CLI, and the Canvas Page API deploy workflow. Use when wiring an AI agent or app to a Source CMS site, building/uploading Drupal Canvas Code Components, deploying landing pages via the Page API, or registering the Source MCP server with Claude Code/Cursor.
---

# Acquia Source

Acquia Source ("Source powered by Drupal CMS") is a managed SaaS CMS wrapping Drupal CMS 11+ and the **Drupal Canvas** page builder (`drupal.org/project/canvas`, formerly Experience Builder). You don't get server/SSH access or arbitrary contrib — you interact through its **JSON:API**, its **MCP server**, the **Canvas Page API**, and the `@drupal-canvas` CLI. Admin/login at `https://source.acquia.com`.

> Acquia Source is a SaaS product, **not** Acquia Cloud Platform. The `acli` CLI manages Cloud Platform, **not** Source sites — don't reach for it here. Source is driven through the web admin + the APIs below.

## Site identity & credentials

- **CMS URL** looks like `https://<uuid>.cms.acquia.site` (auto-generated at site creation; a custom domain can be mapped later). This base URL is the JSON:API host and the OAuth host.
- **API clients** (OAuth2 client_id/secret) are created in the admin UI under **API → API clients → Add API client**.
- The `@drupal-canvas` CLI reads everything from a local `.env` (never committed):
  ```
  CANVAS_SITE_URL=https://<uuid>.cms.acquia.site
  CANVAS_CLIENT_ID=<client_id>
  CANVAS_CLIENT_SECRET=<client_secret>
  CANVAS_JSONAPI_PREFIX=api        # Source serves JSON:API under /api, not the Drupal default /jsonapi
  # CANVAS_ACCESS_TOKEN=<token>    # optional: a pre-issued Bearer token instead of client credentials
  ```

## Authentication (OAuth2 via simple_oauth)

- **Token endpoint:** `POST https://<site>/oauth/token`, `Content-Type: application/x-www-form-urlencoded`.
- **Grants:** Authorization Code (user-present), **Client Credentials** (server/agent — use this for automation), Refresh Token.
- **Request header on API calls:** `Authorization: Bearer <access_token>`.
- **Scopes:** content scopes like `content:read` / `content:write` (examples — the full list isn't published); the Canvas CLI needs `canvas:asset_library` and `canvas:js_component`. Enable Client Credentials + add those scopes when creating the API client.

Client-credentials token, by hand:
```bash
curl -s -X POST "$CANVAS_SITE_URL/oauth/token" \
  -d grant_type=client_credentials \
  -d client_id="$CANVAS_CLIENT_ID" \
  -d client_secret="$CANVAS_CLIENT_SECRET" \
  -d scope="canvas:asset_library canvas:js_component" | jq -r .access_token
```

## JSON:API

- **Base path is `/api` on Source** (Drupal's default `/jsonapi` is overridden — set `CANVAS_JSONAPI_PREFIX=api`). So a collection is `https://<site>/api/<entity_type>/<bundle>` (e.g. `/api/node/article`).
- Resource types are standard Drupal `{entity_type}--{bundle}` (`node--article`, `media--image`, `taxonomy_term--tags`, …). No Source-proprietary prefix confirmed.
- The admin UI has a **JSON:API Query Builder** (API → JSON:API Query Builder) that generates live queries + code, and per-site **OpenAPI documentation** (API → OpenAPI documentation). Use those to discover exact bundles/fields for a given site.
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$CANVAS_SITE_URL/api/node/article?page[limit]=5" | jq '.data[].attributes.title'
```

## MCP server (connect an AI agent)

Acquia Source ships an **MCP server** (HTTP transport, OAuth2 with dynamic client registration). It's **experimental and per-site** — enable it first.

1. **Enable:** admin UI → **Configurations → Experimental features → MCP Server** toggle.
2. **Get the URL:** copy the site's MCP URL from **MCP Client Configuration** in the Source admin (the endpoint URL is provisioned per site; there's no fixed public path to hardcode).
3. **Register in Claude Code:**
   ```bash
   claude mcp add acquia-source-mcp <ACQUIA_SOURCE_SITE_MCP_URL>
   ```
   Then run `/mcp`, select `acquia-source-mcp`, and click **Authenticate** to complete the OAuth flow (dynamic client registration — no manual client_id needed).

**What it exposes** (read-only resources + write tools, via `drupal://` and `canvas://` URIs):
- **Content Management** — content types, media types, vocabularies, text formats; create/update nodes, media, taxonomy terms.
- **Content Modeling** — field storages, field types; create content types and add fields.
- **Drupal Canvas** — components and pages; manage layouts and component properties.

Prefer the MCP server over hand-rolled JSON:API calls when an agent needs to *model content or edit Canvas layouts conversationally*; use JSON:API/the Page API for deterministic, scripted deploys.

## Canvas Code Components — CLI workflow

Scaffold and manage React/JSX Code Components with the official tooling (install the [official Canvas skills](https://github.com/drupal-canvas/skills) for the component-authoring rules — don't reinvent them):

- `npx @drupal-canvas/create@latest` — scaffold a codebase (default template: [acquia/nebula](https://github.com/acquia/nebula), which ships `AGENTS.md` + `SETUP.md` with the Page API reference and pitfalls).
- `npx canvas download` / `npx canvas upload -c <comp1,comp2> -y` — pull/push components between repo and site. `canvas.config.json` (committed) defines structure; `.env` (uncommitted) holds the secrets above.

## Canvas Page API — deploying a page

Pages are built by uploading components, then PATCHing the page with a full component tree. The hard-won rules (these cost hours otherwise):

- **Each PATCH replaces the ENTIRE page.** Never build incrementally with multiple PATCHes — assemble the complete component tree and send it in one atomic request.
- **Version hashes change on every upload.** Re-discover all component version hashes after each `canvas upload`; never hardcode them. Only changed components get new hashes.
- **`FormattedText` strips inline `style` attributes** on the live site (works in Storybook, fails live). For text alignment add a `layout` prop (`left_aligned`/`center_aligned`/`right_aligned`) with CVA variants — never inline `style="text-align:…"`.
- **The `Image` component needs Drupal media-pipeline URLs** (with `alternateWidths`). External URLs / data URIs are accepted without error but render as **invisible 0×0 images** live. For logos use inline SVG/text; for content images upload as Drupal media first.
- **No raw hex colors as props** — use CVA variants mapped to Tailwind theme tokens in `global.css`.
- **Padding stacks:** `section` adds `px-4`, `grid_container` adds `px-6` → ~80px on a 375px screen. Use responsive prefixes (`px-0 md:px-6`) on inner containers.
- **Empty slot containers** need `min-w-*`/`min-h-*` so they stay interactive in the Canvas editor.
- Deploy script pattern: read `.env` → client-credentials token → discover all version hashes in one pass → build the tree (parents before children, fresh UUID per instance, `inputs` as a `json.dumps()` string) → single PATCH. Keep a `VERSIONS` dict at the top.

## Docs

- Overview: https://docs.acquia.com/acquia-source/overview
- API integration (JSON:API): https://docs.acquia.com/acquia-source/api-integration
- Access & authentication (OAuth2): https://docs.acquia.com/acquia-source/access-and-authentication
- MCP server: https://docs.acquia.com/acquia-source/acquia-source-mcp-server
- Creating custom components (CLI): https://docs.acquia.com/acquia-source/creating-custom-components
- JSON:API Query Builder: https://docs.acquia.com/acquia-source/jsonapi-query-builder
- Official Canvas component skills: https://github.com/drupal-canvas/skills · starter template: https://github.com/acquia/nebula
