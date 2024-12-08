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

Copyright © 2024 Javier Aranda. Released under the terms of the [MIT license](LICENSE).
