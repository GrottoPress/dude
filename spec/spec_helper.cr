require "spec"

require "../src/redis"

Spec.around_each do |spec|
  next spec.run if all_tags(spec.example).includes?("skip_around_each")

  if find_parent(spec.example, "no store")
    Dude.settings.store = nil
    next spec.run
  end

  {Dude::Memory.new, Dude::Redis.new(ENV["REDIS_URL"])}.each do |store|
    Dude.settings.store = store
    Dude.settings.store.try(&.truncate)
    spec.run
  end
end

Spec.after_suite { Dude.settings.store.try(&.truncate) }

private def find_parent(example, description)
  return unless example.is_a?(Spec::Item)
  return example if example.description == description
  find_parent(example.parent, description)
end

private def all_tags(example)
  return Set(String).new unless example.is_a?(Spec::Item)
  result = example.tags.try(&.dup) || Set(String).new
  result + all_tags(example.parent)
end
