import { cn } from '../../utils/cn'

interface SkeletonProps {
  className?: string
}

export function Skeleton({ className }: SkeletonProps) {
  return (
    <div
      className={cn('rounded-md bg-dark-700 motion-safe:animate-pulse motion-sensitive', className)}
      aria-hidden="true"
    />
  )
}
