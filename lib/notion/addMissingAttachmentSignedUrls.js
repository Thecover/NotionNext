import { getBlockValue } from 'notion-utils'

export async function addMissingAttachmentSignedUrls(api, recordMap) {
  const signedUrls = recordMap?.signed_urls || {}
  const attachmentBlockIds = Object.entries(recordMap?.block || {})
    .filter(([blockId, blockRecord]) => {
      if (signedUrls[blockId]) return false

      const block = getBlockValue(blockRecord)
      const source = block?.properties?.source?.[0]?.[0]

      return block?.type === 'image' && source?.startsWith('attachment:')
    })
    .map(([blockId]) => blockId)

  if (attachmentBlockIds.length === 0) return recordMap

  const signingRecordMap = {
    ...recordMap,
    signed_urls: {}
  }

  await api.addSignedUrls({
    recordMap: signingRecordMap,
    contentBlockIds: attachmentBlockIds
  })

  recordMap.signed_urls = {
    ...signedUrls,
    ...signingRecordMap.signed_urls
  }

  return recordMap
}
