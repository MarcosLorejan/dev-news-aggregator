import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import DismissToast from '../components/DismissToast'

describe('DismissToast', () => {
  it('announces dismissal and shows countdown', () => {
    render(
      <DismissToast articleTitle="Rust 2024 Edition Highlights" timeLeft={12} onUndo={vi.fn()} />
    )

    expect(screen.getByRole('status')).toHaveTextContent('Article dismissed')
    expect(screen.getByText('Rust 2024 Edition Highlights')).toBeInTheDocument()
    expect(screen.getByText('12s remaining')).toBeInTheDocument()
  })

  it('calls onUndo when undo is clicked', async () => {
    const user = userEvent.setup()
    const onUndo = vi.fn()

    render(<DismissToast articleTitle="Dismissed article" timeLeft={9} onUndo={onUndo} />)

    await user.click(screen.getByRole('button', { name: 'Undo dismiss' }))
    expect(onUndo).toHaveBeenCalledTimes(1)
  })
})
