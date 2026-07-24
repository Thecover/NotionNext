/**
 * Normalize both legacy and current notion-client record-map wrappers to the
 * legacy `{ value: record }` shape used throughout this version of NotionNext.
 */
export function adapterNotionBlockMap(blockMap) {
  if (!blockMap) return blockMap

  const block = {}
  const collection = {}

  for (const [id, value] of Object.entries(blockMap.block || {})) {
    block[id] = { value: unwrapValue(value) }
  }

  for (const [id, value] of Object.entries(blockMap.collection || {})) {
    collection[id] = { value: unwrapValue(value) }
  }

  return {
    ...blockMap,
    block,
    collection
  }
}

function unwrapValue(record) {
  if (!record) return record

  if (record?.value?.value?.id && record?.value?.role) {
    return record.value.value
  }

  if (record?.value?.id && record?.role !== undefined) {
    return record.value
  }

  if (record?.value?.id) {
    return record.value
  }

  return record?.value ?? record
}
