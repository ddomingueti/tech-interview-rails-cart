Sidekiq.configure_server do |config|
  if File.exist?(schedule_file = 'config/schedule.yml') && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end
