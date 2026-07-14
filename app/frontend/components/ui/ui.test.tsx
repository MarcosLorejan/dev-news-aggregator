import { describe, expect, it } from 'vitest'
import { buttonClassName, FOCUS_RING } from './buttonStyles'
import { badgeClassName } from './Badge'

describe('buttonClassName', () => {
  it('includes keyboard focus ring styles', () => {
    expect(buttonClassName()).toContain(FOCUS_RING)
  })

  it('returns primary gradient classes by default', () => {
    const classes = buttonClassName()
    expect(classes).toContain('from-primary-600')
    expect(classes).toContain('to-primary-700')
  })

  it('returns secondary outline classes', () => {
    const classes = buttonClassName({ variant: 'secondary' })
    expect(classes).toContain('border-dark-500')
    expect(classes).toContain('bg-dark-700')
  })

  it('returns active filter classes', () => {
    const classes = buttonClassName({ variant: 'filter', active: true })
    expect(classes).toContain('filter-btn')
    expect(classes).toContain('active')
    expect(classes).toContain('from-primary-600')
  })

  it('returns inactive filter classes', () => {
    const classes = buttonClassName({ variant: 'filter', active: false })
    expect(classes).toContain('filter-btn')
    expect(classes).not.toContain('active')
    expect(classes).toContain('border-dark-500')
    expect(classes).toContain('bg-dark-800')
    expect(classes).toContain('text-gray-200')
  })

  it('maps danger variant to red gradient', () => {
    const classes = buttonClassName({ variant: 'danger' })
    expect(classes).toContain('from-red-600')
  })
})

describe('badgeClassName', () => {
  it('returns primary badge classes', () => {
    const classes = badgeClassName({ variant: 'primary' })
    expect(classes).toContain('from-primary-600/20')
    expect(classes).toContain('rounded-full')
  })

  it('returns orange badge classes', () => {
    const classes = badgeClassName({ variant: 'orange' })
    expect(classes).toContain('from-orange-600/20')
  })
})
