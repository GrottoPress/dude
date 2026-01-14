require "spec"

require "../src/redis"
require "../src/postgres"

Dude::Postgres.create_database(ENV["COCKROACH_URL"])
Dude::Postgres.create_database(ENV["POSTGRES_URL"])

Spec.around_each do |spec|
  next spec.run if all_tags(spec.example).includes?("skip_around_each")

  {
    Dude::Memory.new,
    Dude::Postgres.new(ENV["COCKROACH_URL"]),
    Dude::Postgres.new(ENV["POSTGRES_URL"]),
    Dude::Redis.new(ENV["REDIS_URL"])
  }.each do |store|
    Dude.settings.store = store

    store.as?(Dude::Postgres).try(&.migrate_database)
    Dude.settings.store.try(&.truncate)
    spec.run
  end
end

Spec.after_suite { Dude.settings.store.try(&.truncate) }

private def all_tags(example)
  return Set(String).new unless example.is_a?(Spec::Item)
  result = example.tags.try(&.dup) || Set(String).new
  result + all_tags(example.parent)
end
