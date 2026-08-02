class DigestSerializer
  def self.as_json(digest)
    {
      id: digest.id,
      period: digest.period,
      window_start: digest.window_start,
      window_end: digest.window_end,
      payload: digest.payload,
      created_at: digest.created_at
    }
  end
end
