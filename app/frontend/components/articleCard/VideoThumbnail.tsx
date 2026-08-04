import { useState, type MouseEvent } from 'react'
import { formatDuration } from '../../utils/format'
import { nextYoutubeThumbnail, preferYoutubeThumbnail } from '../../utils/youtubeThumbnail'

interface VideoThumbnailProps {
  title: string
  url: string
  thumbnailUrl?: string | null
  durationSeconds?: number | null
}

function stopPropagation(event: MouseEvent) {
  event.stopPropagation()
}

export default function VideoThumbnail({
  title,
  url,
  thumbnailUrl,
  durationSeconds,
}: VideoThumbnailProps) {
  const duration = formatDuration(durationSeconds)
  const [src, setSrc] = useState(() => preferYoutubeThumbnail(thumbnailUrl) ?? thumbnailUrl ?? null)

  return (
    <a
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className="relative mb-5 block overflow-hidden rounded-xl bg-dark-700 aspect-video group/thumb focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-500"
      onClick={stopPropagation}
      data-testid="video-thumbnail"
      aria-label={`Watch ${title}`}
    >
      {src ? (
        <img
          src={src}
          alt=""
          loading="lazy"
          decoding="async"
          className="h-full w-full object-cover transition-transform duration-200 group-hover/thumb:scale-[1.02]"
          onError={() => {
            setSrc((current) => {
              if (!current) return null
              return nextYoutubeThumbnail(current)
            })
          }}
        />
      ) : (
        <div
          className="flex h-full w-full items-center justify-center bg-gradient-to-br from-dark-600 to-dark-800"
          aria-hidden="true"
        >
          <PlayIcon className="h-12 w-12 text-gray-400 opacity-70" />
        </div>
      )}

      <span
        className="absolute inset-0 flex items-center justify-center bg-black/20 opacity-0 transition-opacity duration-200 group-hover/thumb:opacity-100"
        aria-hidden="true"
      >
        <PlayIcon className="h-14 w-14 text-white drop-shadow-md" />
      </span>

      {duration && (
        <span
          className="absolute bottom-2 right-2 rounded bg-black/80 px-1.5 py-0.5 font-mono text-xs tabular-nums text-white"
          data-testid="video-duration"
        >
          {duration}
        </span>
      )}
    </a>
  )
}

function PlayIcon({ className }: { className: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M8 5.14v13.72a1 1 0 001.5.86l11-6.86a1 1 0 000-1.72l-11-6.86a1 1 0 00-1.5.86z" />
    </svg>
  )
}
