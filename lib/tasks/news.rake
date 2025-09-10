namespace :news do
  desc "Fetch news from all sources"
  task fetch: :environment do
    puts "Starting news aggregation..."

    result = NewsAggregatorService.fetch_all_news

    puts "News aggregation completed!"
    puts "Articles processed: #{result[:articles_count]}"
    puts "Duration: #{result[:duration]}s"
    puts "Sources: #{result[:sources].join(', ')}"
    puts "Timestamp: #{result[:timestamp]}"
  end

  desc "Show latest articles"
  task latest: :environment do
    articles = Article.order(published_at: :desc).limit(10)

    if articles.any?
      puts "Latest 10 articles:"
      articles.each_with_index do |article, index|
        puts "#{index + 1}. #{article.title} (#{article.source_type}) - #{article.published_at.strftime('%m/%d %H:%M')}"
        puts "   #{article.url}"
        puts "   Score: #{article.score}, Comments: #{article.comment_count}"
        puts ""
      end
    else
      puts "No articles found. Run 'rake news:fetch' first."
    end
  end

  desc "Clean old articles (older than 7 days)"
  task clean: :environment do
    old_articles = Article.where("published_at < ?", 7.days.ago)
    count = old_articles.count
    old_articles.delete_all
    puts "Removed #{count} old articles"
  end
end
