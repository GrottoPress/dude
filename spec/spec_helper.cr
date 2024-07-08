require "spec"

require "../src/redis"

stores = {
  Dude::Memory.new,
  Dude::Redis.new(ENV["REDIS_URL"])
}

Spec.around_each do |spec|
  stores.each do |store|
    Dude.settings.store = store
    Dude.settings.store.truncate
    spec.run
  end
end

Spec.after_suite { Dude.settings.store.truncate }
