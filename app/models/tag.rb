class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :slug, :name, presence: true
  validates :slug, uniqueness: true
  validates :slug, inclusion: { in: ArticleTopicClassifier::ALLOWED_SLUGS }

  def self.find_or_create_for_slug!(slug)
    find_or_create_by!(slug: slug) do |tag|
      tag.name = ArticleTopicClassifier.label_for(slug)
    end
  end
end
