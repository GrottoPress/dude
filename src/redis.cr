require "redis"

require "./dude"

module Dude
  struct Redis
    include Store

    getter :client

    def initialize(
      @client : ::Redis::Client,
      @namespace : Symbol | String = :dude
    )
    end

    def self.new(url : String, namespace = :dude)
      new URI.parse(url), namespace
    end

    def self.new(url : URI, namespace = :dude)
      new ::Redis::Client.new(url), namespace
    end

    def key : Key
      Key.new(@namespace)
    end

    def get(key : Symbol | String) : String?
      @client.get(self.key.name key).try &.as(String)
    end

    def transaction(& : Transaction -> _)
      @client.multi do |redis|
        yield Transaction.new(self, redis)
      end
    end

    def truncate
      keys = @client.keys("#{key.name}*")
      @client.del(keys.map &.to_s) unless keys.empty?
    end

    struct Transaction
      include Store::Transaction

      def initialize(@redis : Redis, @client : ::Redis::Transaction)
      end

      def self.new(redis : Redis, url : String)
        new redis, URI.parse(url)
      end

      def self.new(redis : Redis, url : URI)
        new redis, ::Redis::Connection.new(url)
      end

      def self.new(redis : Redis, connection : Redis::Connection)
        new redis, Redis::Transaction.new(connection)
      end

      def set(key : Symbol | String, value, expire)
        @client.set @redis.key.name(key), value, expire
      end

      def delete(key : Symbol | String)
        @client.del @redis.key.name(key)
      end
    end

    struct Key
      getter :namespace

      def initialize(@namespace : Symbol | String)
      end

      def name(*parts : Symbol | String) : String
        "#{name}:#{parts.join(':', &.to_s)}"
      end

      def name : String
        "#{@namespace}:cache"
      end
    end
  end
end
