require "test_helper"

class WithAttributesTest < Minitest::Test
  class User
    extend WithAttributes

    with_attribute :tracking
    with_attribute :notifications, default: false
  end

  class Admin < User
  end

  def teardown
    Thread.current.keys.select { |key| key.start_with?("with_attribute_") }.each do |key|
      Thread.current[key] = nil
    end
  end

  def test_default_values
    assert_predicate User, :tracking?
    assert_predicate User.new, :tracking?

    refute_predicate User, :notifications?
    refute_predicate User.new, :notifications?
  end

  def test_default_values_inheritance
    assert_predicate Admin, :tracking?
    assert_predicate Admin.new, :tracking?
  end

  def test_instance_with_attribute
    user = User.new
    other = User.new

    user.with_notifications do
      assert_predicate user, :notifications?
      refute_predicate User, :notifications?
      refute_predicate other, :notifications?
    end

    refute_predicate user, :notifications?
  end

  def test_instance_without_attribute
    user = User.new
    other = User.new

    user.without_tracking do
      refute_predicate user, :tracking?
      assert_predicate User, :tracking?
      assert_predicate other, :tracking?
    end

    assert_predicate user, :tracking?
  end

  def test_class_with_attribute
    User.with_notifications do
      assert_predicate User, :notifications?
      assert_predicate User.new, :notifications?
      assert_predicate Admin, :notifications?
      assert_predicate Admin.new, :notifications?
    end

    refute_predicate User, :notifications?
    refute_predicate User.new, :notifications?
    refute_predicate Admin, :notifications?
    refute_predicate Admin.new, :notifications?
  end

  def test_class_without_attribute
    User.without_tracking do
      refute_predicate User, :tracking?
      refute_predicate User.new, :tracking?
      refute_predicate Admin, :tracking?
      refute_predicate Admin.new, :tracking?
    end

    assert_predicate User, :tracking?
    assert_predicate User.new, :tracking?
    assert_predicate Admin, :tracking?
    assert_predicate Admin.new, :tracking?
  end

  def test_instance_enable_attribute
    user = User.new
    other = User.new

    user.enable_notifications

    assert_predicate user, :notifications?
    refute_predicate User, :notifications?
    refute_predicate other, :notifications?
  end

  def test_instance_disable_attribute
    user = User.new
    other = User.new

    user.disable_tracking

    refute_predicate user, :tracking?
    assert_predicate User, :tracking?
    assert_predicate other, :tracking?
  end

  def test_class_enable_attribute
    User.enable_notifications

    assert_predicate User, :notifications?
    assert_predicate User.new, :notifications?
    assert_predicate Admin, :notifications?
    assert_predicate Admin.new, :notifications?
  end

  def test_class_disable_attribute
    User.disable_tracking

    refute_predicate User, :tracking?
    refute_predicate User.new, :tracking?
    refute_predicate Admin, :tracking?
    refute_predicate Admin.new, :tracking?
  end

  def test_class_with_attribute_threads
    t1 = Thread.new do
      User.with_notifications do
        assert_predicate User, :notifications?
        assert_predicate User.new, :notifications?
      end
    end

    t2 = Thread.new do
      refute_predicate User, :notifications?
    end

    [t1, t2].each(&:join)
  end

  def test_class_without_attribute_threads
    t1 = Thread.new do
      User.without_tracking do
        refute_predicate User, :tracking?
        refute_predicate User.new, :tracking?
      end
    end

    t2 = Thread.new do
      assert_predicate User, :tracking?
    end

    [t1, t2].each(&:join)
  end
end
