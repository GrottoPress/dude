require "json"

require "redis"

require "./dude/version"
require "./dude/**"

struct Dude
  private module Settings
    class_property! redis_url : String
    class_property redis_pool_size : Int32?
    class_property redis_key_prefix : String = "dude"
  end

  def self.settings
    Settings
  end

  def self.configure : Nil
    yield settings
  end

  getter key : String

  def initialize(key : String)
    @key = self.class.key(key)
  end

  def get(expire)
    get.try { |value| return value }

    yield.try do |block|
      block.tap { |value| set(value, expire) }
    end
  end

  def get(klass : JSON::Serializable.class, expire)
    get(expire) { yield.try(&.to_json) }.try do |value|
      klass.from_json(value.to_s)
    end
  end

  def get
    self.class.redis.get(key)
  end

  def get(klass : JSON::Serializable.class)
    get.try { |value| klass.from_json(value.to_s) }
  end

  def set(value, expire)
    self.class.redis.set(key, value, expire)
  end

  def set(value : JSON::Serializable, expire)
    set(value.to_json, expire)
  end

  def delete
    self.class.redis.del(key)
  end

  def self.get(key, expire)
    new(key).get(expire) { yield }
  end

  def self.get(klass : JSON::Serializable.class, key, expire)
    new(key).get(klass, expire) { yield }
  end

  def self.get(key)
    new(key).get
  end

  def self.get(klass : JSON::Serializable.class, key)
    new(key).get(klass)
  end

  def self.set(key, value, expire)
    new(key).set(value, expire)
  end

  def self.delete(key)
    new(key).delete
  end

  def self.redis
    @@redis ||= begin
      uri = URI.parse(settings.redis_url)

      settings.redis_pool_size.try do |size|
        uri.query_params["max_idle_pool_size"] = size.to_s
      end

      Redis::Client.new(uri)
    end
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
