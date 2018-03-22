require 'sequel'

Sequel::Model.plugin :timestamps

if ENV['RACK_ENV'] == 'production'
  DB = Sequel.postgres(user:     ENV['POSTGRES_USER'],
                       password: ENV['POSTGRES_PASSWORD'],
                       database: ENV['POSTGRES_DATABASE'],
                       host:     ENV['POSTGRES_SOCKET_PATH'])
else
  url = ENV['DATABASE_URL'] ? ENV['DATABASE_URL'] : 'postgres://postgres:postgres@localhost:5432/standbot'
  DB = Sequel.connect(url)
end

require 'standbot/models/standup'
