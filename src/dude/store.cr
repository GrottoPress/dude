module Dude
  module Store
    abstract def get(key : Symbol | String)
    abstract def transaction(& : Transaction -> _)
    abstract def truncate

    macro included
      def delete(key : Symbol | String)
        transaction &.delete(key)
      end

      def set(key : Symbol | String, value, expire)
        transaction &.set(key, value, expire)
      end
    end

    module Transaction
      abstract def delete(key : Symbol | String)
      abstract def set(key : Symbol | String, value, expire)
    end
  end
end
