require "redis"

require "./dude"

module Dude
  class Redis
    module Commands
      def key : Key
        Key.new(@namespace)
      end

      def get(key : Symbol | String) : String?
        @client.get(self.key.name key).try &.as(String)
      end

      def set(key : Symbol | String, value, expire)
        @client.set self.key.name(key), value, expire
      end

      def delete(key : Symbol | String)
        @client.del self.key.name(key)
      end
    end

    include Store
    include Commands

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

    def transaction(& : Transaction -> _)
      @client.multi do |redis|
        yield Transaction.new(redis, @namespace)
      end
    end

    def truncate
      keys = @client.keys("#{key.name}*")
      @client.del(keys.map &.to_s) unless keys.empty?
    end

    class Transaction
      include Store::Transaction
      include Commands

      def initialize(
        @client : ::Redis::Transaction,
        @namespace : Symbol | String = :dude
      )
      end

      def self.new(url : String, namespace = :dude)
        new URI.parse(url), namespace
      end

      def self.new(url : URI, namespace = :dude)
        new ::Redis::Connection.new(url), namespace
      end

      def self.new(connection : Redis::Connection, namespace = :dude)
        new Redis::Transaction.new(connection), namespace
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
