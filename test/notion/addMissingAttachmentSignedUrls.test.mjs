import assert from 'node:assert/strict'
import test from 'node:test'

import { addMissingAttachmentSignedUrls } from '../../lib/notion/addMissingAttachmentSignedUrls.js'

function createImageBlock(id, source) {
  return {
    value: {
      value: {
        id,
        type: 'image',
        file_ids: [`file-${id}`],
        properties: {
          source: [[source]]
        }
      },
      role: 'reader'
    }
  }
}

test('signs nested attachment images without replacing existing signed URLs', async () => {
  const recordMap = {
    block: {
      existing: createImageBlock(
        'existing',
        'attachment:existing-file:existing.jpeg'
      ),
      nested: createImageBlock(
        'nested',
        'attachment:nested-file:gallery-cover.jpeg'
      ),
      external: createImageBlock(
        'external',
        'https://images.example.com/cover.jpeg'
      )
    },
    signed_urls: {
      existing: 'https://file.notion.so/existing'
    }
  }

  const api = {
    async addSignedUrls({ recordMap: signingRecordMap, contentBlockIds }) {
      for (const blockId of contentBlockIds) {
        signingRecordMap.signed_urls[blockId] =
          `https://file.notion.so/${blockId}`
      }
    }
  }

  await addMissingAttachmentSignedUrls(api, recordMap)

  assert.deepEqual(recordMap.signed_urls, {
    existing: 'https://file.notion.so/existing',
    nested: 'https://file.notion.so/nested'
  })
})
