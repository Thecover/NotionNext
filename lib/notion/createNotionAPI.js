import { NotionAPI } from 'notion-client'

const NOTION_API_USER_AGENT =
  'NotionNext/4.6.1 (+https://github.com/notionnext-org/NotionNext)'

/**
 * Create a Notion client with an explicit user agent.
 *
 * Cloudflare rejects the generic `node` user agent used by ofetch, which makes
 * otherwise-public Notion pages return 403 during builds and revalidation.
 */
export function createNotionAPI(options = {}) {
  return new NotionAPI({
    ...options,
    ofetchOptions: {
      ...options.ofetchOptions,
      headers: {
        ...options.ofetchOptions?.headers,
        'user-agent': NOTION_API_USER_AGENT
      }
    }
  })
}
