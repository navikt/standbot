# frozen_string_literal: true

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[rubocop spec]

namespace :db do
  require 'sequel'

  def connect_to_db
    return @db unless @db.nil?
    url = ENV['DATABASE_URL'] ? ENV['DATABASE_URL'] : 'postgres://postgres:postgres@localhost:5432/standbot'
    Sequel.connect(url)
  end

  desc 'Prints current schema version'
  task :version do
    Sequel.extension :migration
    @db = connect_to_db
    version = @db.tables.include?(:schema_info) ? @db[:schema_info].first[:version] : 0
    puts "Schema Version: #{version}"
  end

  desc 'Perform migration up to latest migration available'
  task :migrate do
    Sequel.extension :migration
    @db = connect_to_db
    Sequel::Migrator.run(@db, './db/migrations')
    Rake::Task['db:version'].execute
  end

  desc 'Perform rollback to specified target or full rollback as default'
  task :rollback, :target do |_t, args|
    Sequel.extension :migration
    @db = connect_to_db
    args.with_defaults(target: 0)

    Sequel::Migrator.run(@db, './db/migrations', target: args[:target].to_i)
    Rake::Task['db:version'].execute
  end

  desc 'Perform migration reset (full rollback and migration)'
  task :reset do
    Sequel.extension :migration
    @db = connect_to_db
    Sequel::Migrator.run(@db, './db/migrations', target: 0)
    Sequel::Migrator.run(@db, './db/migrations')
    Rake::Task['db:version'].execute
  end
end
