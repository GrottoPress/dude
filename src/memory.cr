require "./dude"

module Dude
  class Memory < Store
    module Commands
      macro included
        def get(key : Symbol | String) : String?
          @cache[key(key)]?.try do |entry|
            return entry.value unless entry.expired?
            delete(key)
            nil
          end
        end

        def set(key : Symbol | String, value, expire)
          @cache[key(key)] = Entry.new(value, expire)
        end

        def delete(key : Symbol | String)
          @cache.delete key(key)
        end

        private def key(key)
          key.to_s
        end
      end
    end

    include Commands

    def initialize
      @cache = Hash(String, Entry).new
    end

    def transaction(& : Transaction -> _)
      yield Transaction.new(@cache)
    end

    def truncate
      @cache.clear
    end

    class Transaction < Store::Transaction
      include Commands

      def initialize(@cache : Hash(String, Entry))
      end
    end

    struct Entry
      getter :value

      getter expire : Time?

      def initialize(@value : String, expire : Time?)
        @expire = expire.try(&.to_local)
      end

      def self.new(value, expire : Time::Span)
        new(value, expire.from_now)
      end

      def expired? : Bool
        !!@expire.try { |expire| expire <= Time.local }
      end
    end
  end
end
