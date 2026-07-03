namespace :news do
  desc "Enqueue background job to fetch news from all sources"
  task fetch: :environment do
    job = FetchNewsJob.perform_later
    puts "Enqueued FetchNewsJob (job_id: #{job.job_id})"
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

  desc "Clean old articles past the configured retention period"
  task clean: :environment do
    retention_days = NewsAggregatorConfig.retention_days
    cutoff = retention_days.days.ago
    old_articles = Article.where("published_at < ?", cutoff)
    count = old_articles.count
    old_articles.destroy_all
    puts "Removed #{count} articles older than #{retention_days} days (before #{cutoff.to_date})"
  end
end
