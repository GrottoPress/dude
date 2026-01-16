require "redis"

require "./dude"
require "./redis/**"

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
      with_connection &.get(self.key.name key).try &.as(String)
    end

    def transaction(& : Transaction -> _)
      with_transaction do |transaction|
        yield Transaction.new(self, transaction)
      end
    end

    private def with_transaction(&)
      with_connection &.multi { |transaction| yield transaction }
    end

    private def with_connection(&)
      client.@pool.retry do
        client.@pool.checkout do |connection|
          yield connection
        rescue error : IO::Error
          # Triggers a retry
          raise DB::PoolResourceLost.new(connection, cause: error)
        end
      end
    end

    def truncate
      keys = with_connection &.keys("#{key.name}*")
      with_connection &.del(keys.map &.to_s) unless keys.empty?
    end

    struct Transaction
      include Dude::Transaction

      def initialize(@redis : Redis, @transaction : ::Redis::Transaction)
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
        @transaction.set @redis.key.name(key), value, ex: expire
      end

      def delete(key : Symbol | String)
        @transaction.del @redis.key.name(key)
      end
    end
  end
end
