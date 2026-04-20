struct Dude::Postgres
  module Migration
    macro included
      def migrate_database
        create_table
      end

      def rollback_database
        delete_table
      end

      def self.create_database(url : String, default_database = "postgres")
        create_database URI.parse(url), default_database
      end

      def self.create_database(url : URI, default_database = "postgres")
        db_name = url.path.lchop('/')

        default_url = clone_uri(url)
        default_url.path = "/#{default_database}"

        DB.connect(default_url) do |connection|
          create_database(connection, db_name)
        end
      end

      def self.delete_database(url : String, default_database = "postgres")
        delete_database URI.parse(url), default_database
      end

      def self.delete_database(url : URI, default_database = "postgres")
        db_name = url.path.lchop('/')

        default_url = clone_uri(url)
        default_url.path = "/#{default_database}"

        DB.connect(default_url) do |connection|
          delete_database(connection, db_name)
        end
      end

      private def create_table
        with_connection do |connection|
          connection.exec <<-SQL
            CREATE UNLOGGED TABLE IF NOT EXISTS #{cache_table} (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              expires_at TIMESTAMP WITH TIME ZONE
            );
            SQL
        end
      end

      private def delete_table
        with_transaction do |connection|
          connection.exec <<-SQL
            DROP TABLE IF EXISTS #{cache_table} CASCADE;
            SQL
        end
      end

      private def self.create_database(connection, name)
        return if connection.query_one? <<-SQL, name, as: Int32
          SELECT 1::int4 FROM pg_database WHERE datname = $1;
        SQL

        clean_name = PG::EscapeHelper.escape_identifier(name)

        connection.exec <<-SQL
          CREATE DATABASE #{clean_name};
          SQL
      end

      private def self.delete_database(connection, name)
        clean_name = PG::EscapeHelper.escape_identifier(name)
        cascade_sql = cockroachdb?(connection) ? "CASCADE" : ""

        connection.exec <<-SQL
          DROP DATABASE IF EXISTS #{clean_name} #{cascade_sql};
          SQL
      end

      private def self.clone_uri(uri)
        URI.new(
          uri.scheme,
          uri.host,
          uri.port,
          uri.path,
          uri.query,
          uri.user,
          uri.password,
          uri.fragment
        )
      end
    end
  end
end
