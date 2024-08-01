require "./store"

module Dude
  class Memory
    include Store

    getter :data

    def initialize
      @data = Hash(String, Entry).new
    end

    def get(key : Symbol | String) : String?
      @data[key.to_s]?.try do |entry|
        return entry.value unless entry.expired?
        delete(key)
        nil
      end
    end

    def transaction(& : Transaction -> _)
      yield Transaction.new(@data)
    end

    def truncate
      @data.clear
    end

    struct Transaction
      include Store::Transaction

      def initialize(@data : Hash(String, Entry))
      end

      def set(key : Symbol | String, value, expire)
        @data[key.to_s] = Entry.new(value, expire)
      end

      def delete(key : Symbol | String)
        @data.delete(key.to_s)
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
