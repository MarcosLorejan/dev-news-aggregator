# Classifies articles into a fixed topic vocabulary and returns
# schema-validated JSON: { "tags" => ["agents", "security"] }.
# Default strategy is keyword heuristics (no external API). Failures
# return an empty tag list instead of raising.
class ArticleTopicClassifier
  ALLOWED = {
    "agents" => "Agents",
    "rag" => "RAG",
    "security" => "Security",
    "local-llm" => "Local LLM",
    "llms" => "LLMs",
    "webdev" => "Web Dev",
    "devops" => "DevOps",
    "rust" => "Rust",
    "ruby" => "Ruby",
    "javascript" => "JavaScript"
  }.freeze

  ALLOWED_SLUGS = ALLOWED.keys.freeze

  SCHEMA = {
    "type" => "object",
    "required" => [ "tags" ],
    "additionalProperties" => false,
    "properties" => {
      "tags" => {
        "type" => "array",
        "items" => { "type" => "string", "enum" => ALLOWED_SLUGS }
      }
    }
  }.freeze

  PATTERNS = {
    "agents" => [ /\bagents?\b/i, /agentic/i, /autonomous loop/i ],
    "rag" => [ /\brag\b/i, /retrieval[- ]augmented/i, /\bembeddings?\b/i, /\bvector(?:s| db| store)?\b/i ],
    "security" => [ /securit/i, /vulnerab/i, /exploit/i, /malware/i, /ransomware/i, /injection/i, /cve[- ]?\d/i ],
    "local-llm" => [ /local.?llm/i, /\bollama\b/i, /\bgguf\b/i, /on[- ]device/i, /consumer hardware/i ],
    "llms" => [ /\bllms?\b/i, /\bgpt\b/i, /\bclaude\b/i, /openai/i, /language models?/i, /machine learning/i, /\bai\b/i ],
    "webdev" => [ /\breact\b/i, /frontend/i, /css/i, /html/i, /web ?dev/i ],
    "devops" => [ /docker/i, /kubernetes/i, /\bk8s\b/i, /ci\/cd/i, /deploy/i, /devops/i ],
    "rust" => [ /\brust\b/i ],
    "ruby" => [ /\bruby\b/i, /\brails\b/i ],
    "javascript" => [ /javascript/i, /\btypescript\b/i, /\bnode\.?js\b/i ]
  }.freeze

  SOURCE_HINTS = {
    "reddit_MachineLearning" => %w[llms],
    "reddit_artificial" => %w[llms],
    "reddit_LocalLLaMA" => %w[local-llm llms],
    "reddit_rust" => %w[rust],
    "reddit_ruby" => %w[ruby],
    "reddit_javascript" => %w[javascript webdev],
    "reddit_webdev" => %w[webdev],
    "reddit_netsec" => %w[security],
    "reddit_cybersecurity" => %w[security]
  }.freeze

  def self.label_for(slug)
    ALLOWED.fetch(slug)
  end

  def self.classify(article)
    new(article).classify
  end

  def self.apply!(article)
    payload = classify(article)
    slugs = payload.fetch("tags")
    tags = slugs.map { |slug| Tag.find_or_create_for_slug!(slug) }
    article.tags = tags
  rescue StandardError => e
    Rails.logger.warn("ArticleTopicClassifier failed for article #{article.id}: #{e.message}")
    article.tags = [] if article.persisted?
  end

  def initialize(article)
    @article = article
  end

  def classify
    validate_payload!(raw_payload)
  rescue StandardError => e
    Rails.logger.warn("ArticleTopicClassifier invalid payload: #{e.message}")
    { "tags" => [] }
  end

  private

  def raw_payload
    text = [ @article.title, @article.description, @article.source_type ].compact.join("\n")
    matched = PATTERNS.filter_map do |slug, patterns|
      slug if patterns.any? { |pattern| text.match?(pattern) }
    end
    hinted = Array(SOURCE_HINTS[@article.source_type])
    { "tags" => (matched + hinted).uniq }
  end

  def validate_payload!(payload)
    raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)
    raise ArgumentError, "tags missing" unless payload.key?("tags")
    raise ArgumentError, "tags must be an Array" unless payload["tags"].is_a?(Array)

    unknown = payload["tags"] - ALLOWED_SLUGS
    raise ArgumentError, "unknown tags: #{unknown.join(', ')}" if unknown.any?

    extra_keys = payload.keys - [ "tags" ]
    raise ArgumentError, "unexpected keys: #{extra_keys.join(', ')}" if extra_keys.any?

    { "tags" => payload["tags"].uniq }
  end
end
