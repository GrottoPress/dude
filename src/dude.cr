require "json"

require "redis"

require "./dude/version"
require "./dude/**"

struct Dude
  private module Settings
    class_property! redis_url : String
    class_property redis_key_prefix : String = "dude"
  end

  def self.settings
    Settings
  end

  def self.configure : Nil
    yield settings
  end

  getter key : String

  def initialize(key)
    @key = self.class.key(key)
  end

  def get(expire) : String?
    get.try { |value| return value }

    yield.try do |block|
      block.to_json.tap { |value| set(value, expire) }
    end
  end

  def get(klass, expire)
    get(expire) { yield }.try { |value| klass.from_json(value) }
  end

  def get : String?
    self.class.redis.get(key).try &.as(String)
  end

  def get(klass)
    get.try { |value| klass.from_json(value) }
  end

  def set(value, expire)
    self.class.redis.set(key, value, expire)
  end

  def delete
    self.class.redis.del(key)
  end

  def self.get(key, expire)
    new(key).get(expire) { yield }
  end

  def self.get(klass, key, expire)
    new(key).get(klass, expire) { yield }
  end

  def self.get(key)
    new(key).get
  end

  def self.get(klass, key)
    new(key).get(klass)
  end

  def self.set(key, value, expire)
    new(key).set(value, expire)
  end

  def self.delete(key)
    new(key).delete
  end

  def self.redis
    @@redis ||= Redis::Client.new(URI.parse settings.redis_url)
  end

  def self.key : String
    "#{Dude.settings.redis_key_prefix}:cache"
  end

  def self.key(*parts : String) : String
    "#{key}:#{parts.join(':')}"
  end

  def self.truncate
    keys = redis.keys("#{key}*")
    redis.del(keys.map &.to_s) unless keys.empty?
  end
end
