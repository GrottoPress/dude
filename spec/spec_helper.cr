require "spec"

require "../src/dude"

Dude.configure do |settings|
  settings.redis_url = ENV["REDIS_URL"]
end

Spec.before_each { Dude.truncate }

Spec.after_suite { Dude.truncate }

Habitat.raise_if_missing_settings!
