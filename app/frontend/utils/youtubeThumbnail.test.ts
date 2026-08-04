import { describe, expect, it } from 'vitest'
import { nextYoutubeThumbnail, preferYoutubeThumbnail } from './youtubeThumbnail'

describe('youtubeThumbnail', () => {
  it('prefers maxresdefault for known video still URLs', () => {
    expect(preferYoutubeThumbnail('https://i.ytimg.com/vi/abc123/hqdefault.jpg')).toBe(
      'https://i.ytimg.com/vi/abc123/maxresdefault.jpg'
    )
  })

  it('falls down the quality ladder', () => {
    expect(nextYoutubeThumbnail('https://i.ytimg.com/vi/abc123/maxresdefault.jpg')).toBe(
      'https://i.ytimg.com/vi/abc123/sddefault.jpg'
    )
    expect(nextYoutubeThumbnail('https://i.ytimg.com/vi/abc123/hqdefault.jpg')).toBe(
      'https://i.ytimg.com/vi/abc123/mqdefault.jpg'
    )
    expect(nextYoutubeThumbnail('https://i.ytimg.com/vi/abc123/default.jpg')).toBeNull()
  })
})
