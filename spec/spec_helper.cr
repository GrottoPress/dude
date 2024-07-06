require "spec"

require "../src/redis"

Dude.configure do |settings|
  settings.store = Dude::Redis.new(ENV["REDIS_URL"])
end

Spec.before_each { Dude.settings.store.truncate }

Spec.after_suite { Dude.settings.store.truncate }
