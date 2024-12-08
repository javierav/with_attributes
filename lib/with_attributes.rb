require_relative "with_attributes/version"

module WithAttributes
  def with_attribute(*attrs, default: true)
    raise ArgumentError, "invalid with_attribute default option" unless [true, false].include?(default)

    attrs.each do |attr|
      raise NameError, "invalid with_attribute name: #{attr}" unless /^[_A-Za-z]\w*$/.match?(attr)

      class_eval(<<~CODE, __FILE__, __LINE__ + 1)
        def self.#{attr}?
          value = Thread.current["with_attribute_#{attr}_\#{object_id}"]

          if value.nil?
            if superclass.respond_to?(:#{attr}?)
              superclass.#{attr}?
            else
              #{default}
            end
          else
            value
          end
        end

        def self.with_#{attr}
          current = Thread.current["with_attribute_#{attr}_\#{object_id}"]
          enable_#{attr}
          yield if block_given?
        ensure
          Thread.current["with_attribute_#{attr}_\#{object_id}"] = current
        end

        def self.without_#{attr}
          current = Thread.current["with_attribute_#{attr}_\#{object_id}"]
          disable_#{attr}
          yield if block_given?
        ensure
          Thread.current["with_attribute_#{attr}_\#{object_id}"] = current
        end

        def self.enable_#{attr}
          Thread.current["with_attribute_#{attr}_\#{object_id}"] = true
        end

        def self.disable_#{attr}
          Thread.current["with_attribute_#{attr}_\#{object_id}"] = false
        end

        def #{attr}?
          @#{attr}.nil? ? self.class.#{attr}? : @#{attr}
        end

        def with_#{attr}
          current = @#{attr}
          enable_#{attr}
          yield if block_given?
        ensure
          @#{attr} = current
        end

        def without_#{attr}
          current = @#{attr}
          disable_#{attr}
          yield if block_given?
        ensure
          @#{attr} = current
        end

        def enable_#{attr}
          @#{attr} = true
        end

        def disable_#{attr}
          @#{attr} = false
        end
      CODE
    end
  end
end
