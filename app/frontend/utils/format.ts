export function parameterize(value: string): string {
  return value.toLowerCase().replace(/\s+/g, '-')
}

export function humanizeSourceType(sourceType: string): string {
  return sourceType.replace(/_/g, ' ').replace(/\b\w/g, (char) => char.toUpperCase())
}

export function formatPublishedDate(isoDate: string): string {
  return new Date(isoDate).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

export function formatBookmarkedDate(isoDate: string): string {
  return new Date(isoDate).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  })
}

export function formatTimeAgo(isoDate: string): string {
  const seconds = Math.floor((Date.now() - new Date(isoDate).getTime()) / 1000)
  if (seconds < 60) return 'less than a minute ago'
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes} minute${minutes === 1 ? '' : 's'} ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`
  const days = Math.floor(hours / 24)
  return `${days} day${days === 1 ? '' : 's'} ago`
}

export function formatLastUpdated(isoDate: string): string {
  return new Date(isoDate).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

export function formatDetailDate(isoDate: string): string {
  const date = new Date(isoDate)
  const datePart = date.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  })
  const timePart = date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  })
  return `${datePart} at ${timePart}`
}

export function safeExternalUrl(url: string | null | undefined): string | null {
  if (!url) return null
  try {
    const parsed = new URL(url)
    if ((parsed.protocol === 'http:' || parsed.protocol === 'https:') && parsed.host) {
      return url
    }
  } catch {
    return null
  }
  return null
}

export function truncate(text: string, length: number): string {
  if (text.length <= length) return text
  return `${text.slice(0, length)}...`
}

/** Formats seconds as `m:ss` or `h:mm:ss`. Returns null when duration is unknown. */
export function formatDuration(seconds: number | null | undefined): string | null {
  if (seconds == null || !Number.isFinite(seconds) || seconds < 0) return null

  const total = Math.floor(seconds)
  const hours = Math.floor(total / 3600)
  const minutes = Math.floor((total % 3600) / 60)
  const secs = total % 60
  const paddedSecs = String(secs).padStart(2, '0')

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, '0')}:${paddedSecs}`
  }

  return `${minutes}:${paddedSecs}`
}
