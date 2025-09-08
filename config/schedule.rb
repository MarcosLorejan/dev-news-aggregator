# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Set environment
env :PATH, ENV['PATH']
set :output, "log/cron.log"

# Define job types
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

# Fetch news every hour during business hours (9 AM to 6 PM)
every 1.hour, at: [0, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18] do
  rake "news:fetch"
end

# Clean old articles daily at 2 AM
every 1.day, at: '2:00 am' do
  rake "news:clean"
end

# Example of running just once per day
# every 1.day, at: '9:00 am' do
#   rake "news:fetch"
# end
