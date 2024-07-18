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

    def self.new(url : String)
      new URI.parse(url)
    end

    def self.new(url : URI)
      new ::Redis::Client.new(url)
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

      def self.new(url : String)
        new URI.parse(url)
      end

      def self.new(url : URI)
        new ::Redis::Connection.new(url)
      end

      def self.new(connection : Redis::Connection)
        new Redis::Transaction.new(connection)
      end
    end

    struct Key
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
