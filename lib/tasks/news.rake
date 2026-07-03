namespace :news do
  desc "Enqueue background job to fetch news from all sources"
  task fetch: :environment do
    job = FetchNewsJob.perform_later
    puts "Enqueued FetchNewsJob (job_id: #{job.job_id})"
  end

  desc "Show last fetch outcome per source"
  task fetch_status: :environment do
    runs = FetchRun.order(:source_key)

    if runs.none?
      puts "No fetch runs recorded yet. Run 'rake news:fetch' first."
    else
      runs.each do |run|
        line = "#{run.source_key}: #{run.status} (#{run.articles_count} articles"
        line += ", #{run.duration_seconds}s" if run.duration_seconds
        line += ") at #{run.finished_at}"
        puts line
        puts "  #{run.error_class}: #{run.error_message}" if run.failure?
      end

      failed = FetchRun.failed.count
      puts "\n#{failed} source(s) failed on last fetch." if failed.positive?
    end
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
