/**
 * dsh-opencode-go-live — keep the OpenCode Go model routes current.
 *
 * `@deepseek-ai/dsh-llm-pi-ai` ships a static catalog, so a model OpenCode adds
 * to `https://opencode.ai/zen/go/v1/models` is invisible until a harness
 * upgrade. This host plugin fetches that live listing and writes the
 * `llm-pi-ai` provider routes from it, splitting models across one route per
 * wire protocol because a hand-declared route carries a single `api`.
 *
 * A model the installed catalog already describes on the `opencode-go` route
 * is written as a bare `{ id }` so it keeps the catalog's capacities, compat,
 * and thinking levels; a model the catalog does not describe (or one served
 * under a different protocol) is written with the metadata from `catalog.json`.
 *
 * The listing discloses ids only, and OpenCode does not publish a per-model
 * protocol, so a live id absent from `catalog.json` is treated as Chat
 * Completions with conservative capacities.
 *
 * @module dsh-opencode-go-live
 */

import { readFileSync } from 'node:fs'
import { randomUUID } from 'node:crypto'

/** Cordis plugin name used by Loader diagnostics. */
export const name = 'opencode-go-live'

/** The timer service provides `ctx.interval` for the periodic refresh. */
export const inject = ['timer']

/** User-settings namespace owned by `@deepseek-ai/dsh-llm-pi-ai`. */
const SETTINGS_NS = 'llm-pi-ai'

/** Credential reference the pi-ai OpenCode Go catalog expects. */
const CREDENTIAL_REF = 'OPENCODE_API_KEY'

/** The Go tier's live model listing; ids only, no metadata. */
const LISTING_URL = 'https://opencode.ai/zen/go/v1/models'

/** The Go endpoint rejects a chat request without this routing header (400 `MissingSessionID`). */
const SESSION_HEADER = 'x-opencode-session'

/** Re-read the listing every 30 minutes by default. */
const DEFAULT_REFRESH_MS = 30 * 60 * 1000

/** Bound each listing request so a hung endpoint cannot stall the refresh. */
const FETCH_TIMEOUT_MS = 10_000

/** Symbols the settings service reports for a stale `expectedRevision` write. */
const CONFLICT_CODES = new Set(['SETTINGS_CONFLICT'])

const CATALOG = JSON.parse(readFileSync(new URL('./catalog.json', import.meta.url), 'utf8'))

/** Resolve the plugin config with defaults and loud validation. */
function resolveConfig(config) {
  const refreshMs = config?.refreshMs ?? DEFAULT_REFRESH_MS
  if (!Number.isFinite(refreshMs) || refreshMs < 1000) {
    throw new TypeError('opencode-go-live: config.refreshMs must be a number of milliseconds >= 1000')
  }
  return { refreshMs }
}

/** Human-readable labels for the three protocol routes. */
function displayName(route) {
  const suffix = route.replace('opencode-go', '').replace(/^-/, '')
  if (suffix.length === 0) return 'OpenCode Go'
  return `OpenCode Go (${suffix === 'anthropic' ? 'Anthropic' : 'Responses'})`
}

/**
 * Group live ids onto their protocol routes, spelling out entries the installed
 * catalog cannot inherit.
 * @param ids - model ids from the live listing.
 * @param sessionId - value for the endpoint's required routing header.
 * @param catalog - parsed `catalog.json`; defaults to the bundled snapshot.
 * @returns the `llm-pi-ai` `providers` object for the ids.
 */
export function buildProviders(ids, sessionId, catalog = CATALOG) {
  const routeFor = (id) => {
    const known = catalog.byId[id]
    if (known !== undefined) return known.route
    return catalog.hintRoutes?.find(hint => id.startsWith(hint.prefix))?.route ?? 'opencode-go'
  }
  const grouped = new Map()
  for (const id of ids) {
    const known = catalog.byId[id]
    const route = routeFor(id)
    const entry = known?.entry !== undefined ? { id, ...known.entry } : { id }
    const bucket = grouped.get(route)
    if (bucket === undefined) grouped.set(route, [entry])
    else bucket.push(entry)
  }
  const providers = {}
  for (const [route, spec] of Object.entries(catalog.routes)) {
    const models = grouped.get(route)
    if (models === undefined || models.length === 0) continue
    providers[route] = {
      displayName: displayName(route),
      apiKeyEnv: CREDENTIAL_REF,
      api: spec.api,
      baseURL: spec.baseURL,
      headers: { [SESSION_HEADER]: sessionId },
      models,
    }
  }
  return providers
}

/**
 * Mount the refresher and its tools.
 * @param ctx - host cordis context.
 * @param config - deployment config; `refreshMs` sets the interval.
 */
export function apply(ctx, config) {
  const resolved = resolveConfig(config)
  // Stable for the process so repeat requests land on one upstream for cache
  // affinity; llm-pi-ai route headers are static, so it cannot be per session.
  const sessionId = `dsh-${randomUUID()}`
  let lastError
  let lastSyncedAt
  let lastCount

  /** Resolve the Go key through the credential seam, then the process environment. */
  const resolveApiKey = async () => {
    const credentials = ctx.get('credentials')
    if (credentials?.resolve !== undefined) {
      const record = await credentials.resolve(CREDENTIAL_REF)
      if (typeof record?.value === 'string' && record.value.length > 0) return record.value
    }
    const fromEnvironment = process.env[CREDENTIAL_REF]
    return typeof fromEnvironment === 'string' && fromEnvironment.length > 0 ? fromEnvironment : undefined
  }

  /** Fetch the live listing's model ids. */
  const fetchLiveIds = async (apiKey) => {
    const headers = { accept: 'application/json' }
    if (apiKey !== undefined) headers.authorization = `Bearer ${apiKey}`
    const response = await fetch(LISTING_URL, { headers, signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) })
    if (!response.ok) throw new Error(`GET ${LISTING_URL} answered ${response.status}`)
    const body = await response.json()
    const entries = Array.isArray(body?.data) ? body.data : Array.isArray(body?.models) ? body.models : []
    const ids = entries
      .map(entry => (typeof entry === 'string' ? entry : entry?.id))
      .filter(id => typeof id === 'string' && id.length > 0)
    return [...new Set(ids)]
  }

  /** The `llm-pi-ai` namespace revision, for optimistic writes. */
  const currentRevision = () => {
    const settings = ctx.get('settings')
    if (settings?.describe === undefined) return undefined
    return settings.describe().find(descriptor => descriptor.ns === SETTINGS_NS)?.revision
  }

  /** Write, retrying once against a concurrent editor's revision. */
  const write = async (settings, patch) => {
    const revision = currentRevision()
    try {
      await settings.update(SETTINGS_NS, patch, revision)
    } catch (error) {
      const code = error !== null && typeof error === 'object' ? error.code : undefined
      if (!CONFLICT_CODES.has(code) && !/conflict/i.test(String(error?.message ?? ''))) throw error
      await settings.update(SETTINGS_NS, patch, currentRevision())
    }
  }

  /**
   * Read the live listing and write the routes.
   * @returns `{ count, routes }` for the models just written.
   */
  const refresh = async () => {
    const settings = ctx.get('settings')
    if (settings?.update === undefined) {
      throw new Error('opencode-go-live: the settings service is unavailable; mount dsh-settings-file')
    }
    const apiKey = await resolveApiKey()
    const ids = await fetchLiveIds(apiKey)
    const providers = buildProviders(ids, sessionId)
    if (Object.keys(providers).length === 0) {
      throw new Error('opencode-go-live: the live listing returned no models')
    }
    const patch = { providers }
    const current = settings.get(SETTINGS_NS)?.providers
    const unchanged = Object.keys(providers).every(route =>
      JSON.stringify(current?.[route]) === JSON.stringify(providers[route]))
    if (!unchanged) await write(settings, patch)
    lastSyncedAt = new Date().toISOString()
    lastError = undefined
    lastCount = ids.length
    const routes = Object.fromEntries(Object.entries(providers).map(([route, profile]) => [route, profile.models.length]))
    return { count: ids.length, routes, unchanged }
  }

  /** Refresh without throwing, so one failed tick cannot stop the interval. */
  const refreshQuietly = async () => {
    try {
      await refresh()
      ctx.logger?.info?.(`opencode-go-live: synced ${lastCount} OpenCode Go models`)
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error)
      ctx.logger?.warn?.(`opencode-go-live: refresh failed: ${lastError}`)
    }
  }

  const runNow = async () => {
    try {
      return await refresh()
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error)
      throw error
    }
  }

  if (ctx.interval !== undefined) {
    ctx.interval(() => { void refreshQuietly() }, resolved.refreshMs)
  }
  // The first sync waits for the settings service: applying the plugin during
  // tree load can precede it, and a one-shot tick would then be lost until the
  // next interval. Credentials resolve per request, so only settings gates it.
  ctx.inject(['settings'], () => { void refreshQuietly() })

  ctx.inject(['tools'], (toolsCtx) => {
    const textOutput = render => ({ schema: { type: 'object' }, render: (_args, value) => [{ type: 'text', text: render(value) }] })

    toolsCtx.tools.register({
      name: 'oc_go_status',
      description: 'Report the OpenCode Go model routes managed by dsh-opencode-go-live: last sync time, model count, and any last refresh error. Read-only.',
      parameters: { type: 'object', properties: {} },
      output: textOutput(value => JSON.stringify(value, null, 2)),
      isConcurrencySafe: () => true,
      timeoutMs: 5000,
      execute: () => ({
        lastSyncedAt,
        lastCount,
        lastError,
        refreshMs: resolved.refreshMs,
        credentialRef: CREDENTIAL_REF,
      }),
    })

    toolsCtx.tools.register({
      name: 'oc_go_sync',
      description: 'Fetch the live OpenCode Go model listing now and write the llm-pi-ai provider routes for it. Use when a model the endpoint serves is missing from the picker.',
      parameters: { type: 'object', properties: {} },
      output: textOutput(value => JSON.stringify(value, null, 2)),
      timeoutMs: 30000,
      execute: () => runNow(),
    })
  })
}
