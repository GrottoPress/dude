struct Dude::Redis
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
