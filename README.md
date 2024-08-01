# Dude

**Dude** is a dead simple Redis cache that supports multiple storage backends.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     dude:
       github: GrottoPress/dude
     #redis: # Uncomment if using the Redis backend
     #  github: jgaskins/redis
   ```

1. Run `shards update`

1. Require and configure *Dude*:

   - Using the Redis backend

     ```crystal
     # ->>> src/app/config.cr

     # ...

     require "dude/redis"

     Dude.configure do |settings|
       settings.store = Dude::Redis.new(
         "redis://localhost:6379/0",
         namespace: "dude"
       )
     end

     # ...
     ```

   - Using the Memory backend

     ```crystal
     # ->>> src/app/config.cr

     # ...

     require "dude"

     Dude.configure do |settings|
       settings.store = Dude::Memory.new
     end

     # ...
     ```

   - Skip caching

     You may disable cache altogether by setting `Dude.settings.store` to `nil` (This is the default).


## Usage

- Fetch raw value from cache

  ```crystal
  # Sets and returns block if key not found in cache
  Dude.get("key", 1.minute) { "value" } # => `value`
  ```

- Fetch JSON-serializable value from cache

  ```crystal
  struct User
    include JSON::Serializable

    getter id : Int32

    def initialize(@id)
    end
  end

  # Sets and returns block if key not found in cache
  Dude.get(User, "key", 1.minute) { User.new(2) } # => `User(@id=2)`
  ```

- Perform multiple operations using a transaction

  ```crystal
  Dude.transaction do |store|
    Dude.set("key_1", "value1", 1.minute, store)
    Dude.set("key_2", "value2", 3.minutes, store)
    Dude.delete("key_3", store)
  end
  ```

## Development

Create a `.env.sh` file:

```bash
#!/bin/bash

export REDIS_URL='redis://localhost:6379/0'
```

Update the file with your own details. Then run tests with `source .env.sh && crystal spec`.

## Contributing

1. [Fork it](https://github.com/GrottoPress/dude/fork)
1. Switch to the `master` branch: `git checkout master`
1. Create your feature branch: `git checkout -b my-new-feature`
1. Make your changes, updating changelog and documentation as appropriate.
1. Commit your changes: `git commit`
1. Push to the branch: `git push origin my-new-feature`
1. Submit a new *Pull Request* against the `GrottoPress:master` branch.
