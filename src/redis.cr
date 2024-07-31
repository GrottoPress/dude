require "redis"

require "./dude"

module Dude
  class Redis
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

    def get(key : Symbol | String)
      previous_def.first.try(&.as? String)
    end

    def transaction(& : Transaction -> _)
      @client.multi do |redis|
        yield Transaction.new(redis, key)
      end
    end

    def truncate
      keys = @client.keys("#{key.name}*")
      @client.del(keys.map &.to_s) unless keys.empty?
    end

    struct Transaction
      include Store::Transaction

      def initialize(@client : ::Redis::Transaction, @key : Key)
      end

      def self.new(url : String, key : Key)
        new URI.parse(url), key
      end

      def self.new(url : URI, key : Key)
        new ::Redis::Connection.new(url), key
      end

      def self.new(connection : Redis::Connection, key : Key)
        new Redis::Transaction.new(connection), key
      end

      def get(key : Symbol | String) : String?
        @client.get(@key.name key).try &.as(String)
      end

      def set(key : Symbol | String, value, expire)
        @client.set @key.name(key), value, expire
      end

      def delete(key : Symbol | String)
        @client.del @key.name(key)
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
