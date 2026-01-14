require "pg"

require "./dude"
require "./postgres/**"

module Dude
  struct Postgres
    include Store
    include Migration

    getter :client, :cache_table

    def initialize(
      @client : DB::Database,
      namespace : Symbol | String = ""
    )
      @cache_table = namespace.to_s.empty? ?
        "cache_entries" :
        "#{namespace}_cache_entries"
    end

    def self.new(url, namespace = :dude)
      new DB.open(url), namespace
    end

    def get(key : Symbol | String) : String?
      with_transaction do |connection|
        connection.exec <<-SQL
          DELETE FROM #{cache_table}
          WHERE expires_at IS NOT NULL AND expires_at <= CURRENT_TIMESTAMP;
          SQL

        connection.query_one? <<-SQL, key, as: String
          SELECT value FROM #{cache_table} WHERE key = $1;
          SQL
      end
    end

    def transaction(& : Transaction -> _)
      with_transaction do |connection|
        yield Transaction.new(self, connection)
      end
    end

    def truncate
      with_connection &.exec <<-SQL
        TRUNCATE TABLE #{cache_table};
        SQL
    end

    private getter? cockroachdb : Bool do
      with_connection { |connection| self.class.cockroachdb?(connection) }
    end

    private def with_transaction(&)
      with_connection &.transaction do |transaction|
        yield transaction.connection
      end
    end

    private def with_connection(&)
      client.retry do
        client.using_connection { |connection| yield connection }
      end
    end

    protected def self.cockroachdb?(connection)
      version = connection.scalar("SELECT version();").as(String)
      version.starts_with?("CockroachDB")
    end

    struct Transaction
      include Store::Transaction

      def initialize(@postgres : Postgres, @connection : DB::Connection)
      end

      def set(key : Symbol | String, value, expire)
        @connection.exec <<-SQL, key, value, expires_at(expire)
          INSERT INTO #{@postgres.cache_table} (key, value, expires_at)
          VALUES ($1, $2, $3)
          ON CONFLICT (key) DO UPDATE SET value = $2, expires_at = $3;
          SQL
      end

      def delete(key : Symbol | String)
        @connection.exec <<-SQL, key
          DELETE FROM #{@postgres.cache_table} WHERE key = $1;
          SQL
      end

      private def expires_at(expire)
        case expire
        when Time::Span
          expire.from_now
        when Time
          expire
        else
          expire.try(&.to_i64.seconds.from_now)
        end
      end
    end
  end
end
