import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { buttonClassName } from './ui/buttonStyles'

/** Relative luminance for sRGB hex (#rgb or #rrggbb). */
function luminance(hex: string): number {
  const normalized = hex.replace('#', '')
  const full =
    normalized.length === 3
      ? normalized
          .split('')
          .map((c) => c + c)
          .join('')
      : normalized
  const channels = [0, 2, 4].map((i) => {
    const value = Number.parseInt(full.slice(i, i + 2), 16) / 255
    return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4
  })
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
}

function contrastRatio(foreground: string, background: string): number {
  const lighter = Math.max(luminance(foreground), luminance(background))
  const darker = Math.min(luminance(foreground), luminance(background))
  return (lighter + 0.05) / (darker + 0.05)
}

describe('feed UI contrast tokens', () => {
  // Colors intentionally match opaque surface panels + lightened captions.
  const SURFACE = '#1e293b' // surface-card / dark-800
  const SUBTITLE = '#d1d5db' // gray-300
  const BODY = '#e5e7eb' // gray-200
  const METADATA = '#d1d5db' // gray-300
  const FILTER_INACTIVE = '#e5e7eb' // gray-200 on dark-800

  it('meets WCAG AA for body, caption, and metadata on card surfaces', () => {
    expect(contrastRatio(BODY, SURFACE)).toBeGreaterThanOrEqual(4.5)
    expect(contrastRatio(SUBTITLE, SURFACE)).toBeGreaterThanOrEqual(4.5)
    expect(contrastRatio(METADATA, SURFACE)).toBeGreaterThanOrEqual(4.5)
  })

  it('uses high-contrast inactive filter button classes', () => {
    const className = buttonClassName({ variant: 'filter', active: false })
    expect(className).toContain('text-gray-200')
    expect(className).toContain('bg-dark-800')
    expect(className).toContain('border-dark-500')
    expect(contrastRatio(FILTER_INACTIVE, SURFACE)).toBeGreaterThanOrEqual(4.5)
  })

  it('defines opaque surface panel backgrounds in application.css', () => {
    const cssPath = resolve(__dirname, '../entrypoints/application.css')
    const css = readFileSync(cssPath, 'utf8')
    expect(css).toMatch(/\.surface-card\s*\{[^}]*background:\s*#1e293b/s)
    expect(css).toMatch(/\.surface-elevated\s*\{[^}]*background:\s*#1e293b/s)
    expect(css).not.toMatch(/\.surface-card\s*\{[^}]*background:\s*rgba\(/s)
  })
})
