import { useCallback, useState, type ReactNode } from 'react'
import ConfirmDialog from '../components/ConfirmDialog'

export interface ConfirmOptions {
  title?: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  confirmTone?: 'danger' | 'primary'
}

interface PendingConfirm extends ConfirmOptions {
  resolve: (value: boolean) => void
}

export function useConfirmDialog(): {
  confirm: (options: ConfirmOptions) => Promise<boolean>
  dialog: ReactNode
} {
  const [pending, setPending] = useState<PendingConfirm | null>(null)

  const confirm = useCallback((options: ConfirmOptions) => {
    return new Promise<boolean>((resolve) => {
      setPending({ ...options, resolve })
    })
  }, [])

  const close = useCallback((result: boolean) => {
    setPending((current) => {
      current?.resolve(result)
      return null
    })
  }, [])

  const dialog = pending ? (
    <ConfirmDialog
      open
      title={pending.title}
      message={pending.message}
      confirmLabel={pending.confirmLabel}
      cancelLabel={pending.cancelLabel}
      confirmTone={pending.confirmTone}
      onConfirm={() => close(true)}
      onCancel={() => close(false)}
    />
  ) : null

  return { confirm, dialog }
}
