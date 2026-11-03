# WithAttributes

[![Testing](https://github.com/javierav/with_attributes/actions/workflows/testing.yml/badge.svg)](https://github.com/javierav/with_attributes/actions/workflows/testing.yml)

Temporarily enabling or disabling boolean attributes on classes and instances using `with` and `without` dynamic methods.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "with_attributes"
```

And then execute:

```shell
bundle install
```

## Usage

```ruby
class User
  extend WithAttributes

  with_attribute :notifications, default: false
end
```

This add the following methods:

* `User.with_notifications` for enable notifications in class-level during block execution.

* `User.without_notifications` for disable notifications in class-level during block execution.

* `User.enable_notifications`for enable notifications in class-level permanently.

* `User.disable_notifications`for disable notifications in class-level permanently.

* `User.notifications?`for check current status of notifications in class-level, using default value if not inside `with_notifications` or `without_notifications` modifiers.

* `user.with_notifications` for enable notifications in instance-level during block execution.

* `user.without_notifications` for disable notifications in instance-level during block execution.

* `user.enable_notifications`for enable notifications in instance-level permanently.
- `user.disable_notifications`for disable notifications in instance-level permanently.

- `user.notifications?`for check current status of notifications in instance-level, using class-level value if not inside `with_notifications` or `without_notifications` modifiers.

Example using class-level methods:

```ruby
# using default value
User.notifications? # => false

User.with_notifications do
  User.notifications? # => true

  User.without_notifications do
    User.notifications? # => false
  end

  User.notifications? # => true
end

User.notifications? # => false
```

Example using instance level methods:

```ruby
user = User.new

# if notifications is not changed in this instance, using value of class or default if class value is also not changed
user.notifications? # => false

# changing value in class-level
User.with_notifications do
  user.notifications? # => true
end

# changing value in instance-level
user.with_notifications do
  user.notifications? # => true
end

# using nested
User.with_notifications do
  user.without_notifications do
    user.notifications? # => false
  end
end
```

## Real world example

```ruby
module Trackable
  extend ActiveSupport::Concern

  class_methods do
    include WithAttributes
  end

  included do
    with_attribute :tracking, default: true

    with_options if: :tracking? do
      after_create  { ... }
      after_update  { ... }
      after_destroy { ... }
    end
  end
end

class User
  include Trackable
end

User.without_tracking do
  User.create(...)
end

User.find(...).tap do |user|
  user.without_tracking do
    user.update(...)
  end
end
```

## Active Record transactions

The `with_*` and `without_*` modifiers restore the previous value as soon as the block ends. Active Record runs `after_commit` and `after_rollback` callbacks when the outermost transaction finishes, so if that transaction wraps the modifier, these callbacks run after the block has ended and see the original value:

```ruby
class User < ApplicationRecord
  extend WithAttributes

  with_attribute :tracking, default: true

  after_create { tracking? }             # runs inside the block
  after_commit :track, if: :tracking?    # runs after the block
end

User.transaction do
  User.without_tracking do
    User.create(...) # after_create sees tracking? => false
  end
end # after_commit sees tracking? => true, so the user is tracked
```

This affects both class-level and instance-level modifiers. Callbacks such as `after_create`, `after_update` and `after_destroy` are not affected, because they run inside the block.

There are several ways to avoid it:

* Keep the whole transaction inside the block. A single `User.create(...)` outside of any transaction also works, because its implicit transaction commits inside the block. This doesn't help if there is another transaction around it, such as one opened by the caller, because the commit is still delayed until the outermost transaction finishes.

  ```ruby
  User.without_tracking do
    User.transaction do
      User.create(...)
    end
  end
  ```

* Save the value in a callback that runs inside the block and check it in `after_commit`. This works however many transactions are around it.

  ```ruby
  after_save { @tracked = tracking? }
  after_commit :track, if: -> { @tracked }
  ```

* Use `user.disable_tracking` or `user.enable_tracking` on the instance, because they aren't restored when a block ends. The value stays on that instance until it is changed again.

Avoid `User.disable_tracking` and `User.enable_tracking` for this: the value stays for the whole thread, so it would also apply to later code running in that thread, for example the next request handled by the same server thread.

## Thread safety

Thread safety is guaranteed using class-level methods. Instance-level methods only are thread safe if each thread not share the same instance with others.

```ruby
# thread safe example

t1 = Thread.new do
  User.without_notifications do
    User.create(...) # user created without notifications
  end
end

t2 = Thread.new do
  User.with_notifications do
    User.create(...) # user created with notifications
  end
end

[t1, t2].map(&:join)
```

```ruby
# thread safe example

t1 = Thread.new do
  user = User.find(...)

  user.without_notifications do
    user.update(...) # user updated without notifications
  end
end

t2 = Thread.new do
  user = User.find(...)

  user.with_notifications do
    user.update(...) # user updated with notifications
  end
end

[t1, t2].map(&:join)
```

```ruby
# thread unsafe example

user = User.new

t1 = Thread.new do
  user.without_notifications do
    user.update(...) # unexpected behaviour, can be created with or without notifications
  end
end

t2 = Thread.new do
  user.with_notifications do
    user.update(...) # unexpected behaviour, can be created with or without notifications
  end
end

[t1, t2].map(&:join)
```

## Licence

Copyright © 2024-2026 Javier Aranda. Released under the terms of the [MIT license](LICENSE).
