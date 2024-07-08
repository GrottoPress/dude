require "json"

require "./dude/version"
require "./dude/**"

module Dude
  private module Settings
    class_property store : Store?
  end

  extend self

  def settings
    Settings
  end

  def configure : Nil
    yield settings
  end

  def get(klass, key, expire)
    get(key, expire) { yield }.try { |value| klass.from_json(value) }
  end

  def get(key, expire) : String?
    get(key).try { |value| return value }

    yield.try do |block|
      block.to_json.tap { |value| set(key, value, expire) }
    end
  end

  def get(klass, key)
    get(key).try { |value| klass.from_json(value) }
  end

  def get(key) : String?
    settings.store.try &.get(key)
  end

  def set(key, value, expire, store : Store::Transaction? = nil)
    store ||= settings.store
    store.try &.set(key, value, expire)
  end

  def delete(key, store : Store::Transaction? = nil)
    store ||= settings.store
    store.try &.delete(key)
  end

  def transaction(& : Store::Transaction -> _)
    settings.store.try &.transaction { |transaction| yield transaction }
  end
end
