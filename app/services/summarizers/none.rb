module Summarizers
  class None < Base
    def summarize(_article)
      nil
    end
  end
end
