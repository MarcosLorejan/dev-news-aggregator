import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from 'react'
import { buttonClassName, type ButtonColor, type ButtonSize, type ButtonVariant } from './buttonStyles'

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  size?: ButtonSize
  color?: ButtonColor
  active?: boolean
  children: ReactNode
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = 'primary',
    size = 'md',
    color = 'primary',
    active = false,
    className,
    children,
    ...props
  },
  ref
) {
  return (
    <button
      ref={ref}
      type="button"
      className={buttonClassName({ variant, size, color, active, className })}
      {...props}
    >
      {children}
    </button>
  )
})

export default Button
export { buttonClassName }
