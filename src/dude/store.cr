module Dude
  abstract class Store
    module Commands
      macro included
        abstract def delete(key : Symbol | String)
        abstract def get(key : Symbol | String)
        abstract def set(key : Symbol | String, value, expire)
      end
    end

    include Commands

    abstract def transaction(& : Transaction -> _)
    abstract def truncate

    abstract class Transaction
      include Commands
    end
  end
end
