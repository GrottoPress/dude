module Dude
  module Store
    module Commands
      abstract def delete(key : Symbol | String)
      abstract def get(key : Symbol | String)
      abstract def set(key : Symbol | String, value, expire)
    end

    include Commands

    abstract def transaction(& : Transaction -> _)
    abstract def truncate

    module Transaction
      include Commands
    end
  end
end
