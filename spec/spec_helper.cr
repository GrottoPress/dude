require "spec"

require "../src/redis"
require "../src/postgres"

private STORES = {
  Dude::Memory.new,
  Dude::Postgres.new(ENV["COCKROACH_URL"]),
  Dude::Postgres.new(ENV["POSTGRES_URL"]),
  Dude::Redis.new(ENV["REDIS_URL"])
}

Spec.around_each do |spec|
  next spec.run if all_tags(spec.example).includes?("skip_around_each")

  STORES.each_with_index do |store, i|
    Dude.settings.store = store

    store.as?(Dude::Postgres).try(&.migrate_database)
    Dude.settings.store.try(&.truncate)
    spec.run
    puts STORES[i].class
  end
end

Spec.after_suite { Dude.settings.store.try(&.truncate) }

private def all_tags(example)
  return Set(String).new unless example.is_a?(Spec::Item)
  result = example.tags.try(&.dup) || Set(String).new
  result + all_tags(example.parent)
end
