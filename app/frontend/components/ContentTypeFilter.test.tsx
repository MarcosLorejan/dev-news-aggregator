import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import ContentTypeFilter, {
  contentTypeFilterParams,
  maxDurationFilterParams,
  parseContentTypeFilter,
  parseMaxDurationFilter,
} from './ContentTypeFilter'

describe('ContentTypeFilter', () => {
  it('marks the active type and duration pills with aria-pressed', () => {
    render(
      <ContentTypeFilter
        activeContentType="video"
        activeMaxDuration="20"
        onContentTypeChange={vi.fn()}
        onMaxDurationChange={vi.fn()}
      />
    )

    expect(screen.getByRole('button', { name: 'Videos' })).toHaveAttribute('aria-pressed', 'true')
    expect(screen.getByRole('button', { name: 'All' })).toHaveAttribute('aria-pressed', 'false')
    expect(screen.getByRole('button', { name: '≤ 20 min' })).toHaveAttribute('aria-pressed', 'true')
    expect(screen.getByRole('button', { name: 'Any length' })).toHaveAttribute('aria-pressed', 'false')
  })

  it('notifies when type or duration pills are clicked', async () => {
    const user = userEvent.setup()
    const onContentTypeChange = vi.fn()
    const onMaxDurationChange = vi.fn()

    render(
      <ContentTypeFilter
        activeContentType="all"
        activeMaxDuration="all"
        onContentTypeChange={onContentTypeChange}
        onMaxDurationChange={onMaxDurationChange}
      />
    )

    await user.click(screen.getByRole('button', { name: 'Articles' }))
    await user.click(screen.getByRole('button', { name: '≤ 10 min' }))

    expect(onContentTypeChange).toHaveBeenCalledWith('article')
    expect(onMaxDurationChange).toHaveBeenCalledWith('10')
  })
})

describe('content type filter helpers', () => {
  it('maps filter values to request params', () => {
    expect(contentTypeFilterParams('all')).toEqual({})
    expect(contentTypeFilterParams('video')).toEqual({ content_type: 'video' })
    expect(maxDurationFilterParams('all')).toEqual({})
    expect(maxDurationFilterParams('20')).toEqual({ max_duration: 20 })
  })

  it('parses URL values with safe defaults', () => {
    expect(parseContentTypeFilter('video')).toBe('video')
    expect(parseContentTypeFilter('nope')).toBe('all')
    expect(parseMaxDurationFilter('10')).toBe('10')
    expect(parseMaxDurationFilter('99')).toBe('all')
  })
})
