export function sortOrdersNewestFirst(list) {
  return (list || []).slice().sort((a, b) => {
    const aTime = new Date(a?.order_date || 0).getTime()
    const bTime = new Date(b?.order_date || 0).getTime()
    if (bTime !== aTime) return bTime - aTime

    const aCreated = new Date(a?.created_at || 0).getTime()
    const bCreated = new Date(b?.created_at || 0).getTime()
    if (bCreated !== aCreated) return bCreated - aCreated

    return Number(b?.id || 0) - Number(a?.id || 0)
  })
}