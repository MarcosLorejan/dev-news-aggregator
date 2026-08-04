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
    # Destroy in batches so dependents run callbacks without loading the full set.
    old_articles.in_batches(of: 500) do |batch|
      batch.destroy_all
    end
    puts "Removed #{count} articles older than #{retention_days} days (before #{cutoff.to_date})"
  end

  desc "Show Reddit OAuth status without printing secrets"
  task reddit_oauth_status: :environment do
    require Rails.root.join("lib/local_env")
    LocalEnv.load! if Rails.env.development?

    id = LocalEnv.present_masked("REDDIT_CLIENT_ID")
    secret = LocalEnv.present_masked("REDDIT_CLIENT_SECRET")
    configured = NewsFetchers::RedditFetcher.oauth_configured?
    path = configured ? "oauth_json" : "atom_rss"

    puts "Reddit OAuth status (values never printed):"
    puts "  REDDIT_CLIENT_ID:     present=#{id[:present]} length=#{id[:length]}"
    puts "  REDDIT_CLIENT_SECRET: present=#{secret[:present]} length=#{secret[:length]}"
    puts "  oauth_configured:     #{configured}"
    puts "  fetch_path:           #{path}"

    if configured
      puts "  hint: new Reddit articles should persist score/comment_count from JSON listings."
    else
      puts "  hint: copy .env.example → .env, set both REDDIT_* keys, restart Rails (dev.ps1 / bin/dev load .env)."
      puts "  Without credentials, Atom RSS is used and scores stay 0 on create."
    end

    begin
      reddit_runs = FetchRun.where("source_key LIKE ?", "reddit_%").order(:source_key)
      if reddit_runs.any?
        puts "\nRecent Reddit FetchRun outcomes:"
        reddit_runs.each do |run|
          line = "  #{run.source_key}: #{run.status} (#{run.articles_count} articles) at #{run.finished_at}"
          line += " — #{run.error_class}" if run.failure?
          puts line
        end
      else
        puts "\nNo Reddit FetchRun rows yet. Run: bin/rails news:fetch"
      end
    rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError => e
      puts "\nSkipped FetchRun lookup (database unavailable): #{e.class}"
    end
  end
end
