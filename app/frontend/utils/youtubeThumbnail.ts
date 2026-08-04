const QUALITY_LADDER = ['maxresdefault', 'sddefault', 'hqdefault', 'mqdefault', 'default'] as const

/** Prefer maxres when we only have a lower Atom-quality still URL. */
export function preferYoutubeThumbnail(url: string | null | undefined): string | null {
  if (!url) return null
  const match = url.match(/\/vi\/([^/]+)\//)
  if (!match) return url
  return `https://i.ytimg.com/vi/${match[1]}/maxresdefault.jpg`
}

/** Next lower YouTube still quality, or null when the ladder is exhausted. */
export function nextYoutubeThumbnail(url: string): string | null {
  for (let index = 0; index < QUALITY_LADDER.length - 1; index += 1) {
    const current = QUALITY_LADDER[index]
    const next = QUALITY_LADDER[index + 1]
    if (url.includes(`/${current}.jpg`)) {
      return url.replace(`/${current}.jpg`, `/${next}.jpg`)
    }
  }
  return null
}
