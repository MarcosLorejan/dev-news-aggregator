import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import TermChipInput, { addTerm } from '../components/TermChipInput'

describe('addTerm', () => {
  it('trims, downcases and dedupes', () => {
    expect(addTerm(['ruby'], ' Ruby ')).toEqual(['ruby'])
    expect(addTerm(['ruby'], 'Rails')).toEqual(['ruby', 'rails'])
  })

  it('ignores blank values', () => {
    expect(addTerm(['ruby'], '   ')).toEqual(['ruby'])
  })
})

describe('TermChipInput', () => {
  it('adds a term on Enter and clears the draft', async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<TermChipInput terms={[]} onChange={onChange} />)

    await user.type(screen.getByTestId('term-chip-input-field'), 'rust{Enter}')

    expect(onChange).toHaveBeenCalledWith(['rust'])
  })

  it('removes the last term on Backspace when the draft is empty', async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<TermChipInput terms={['ruby', 'rails']} onChange={onChange} />)

    await user.click(screen.getByTestId('term-chip-input-field'))
    await user.keyboard('{Backspace}')

    expect(onChange).toHaveBeenCalledWith(['ruby'])
  })

  it('removes a specific term via its button', async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<TermChipInput terms={['ruby', 'rails']} onChange={onChange} />)

    await user.click(screen.getByRole('button', { name: 'Remove rails' }))

    expect(onChange).toHaveBeenCalledWith(['ruby'])
  })
})
