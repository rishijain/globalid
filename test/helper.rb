require 'bundler/setup'
require 'forwardable'
require 'active_support'
require 'autorun'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'

require 'global_id'
require 'models/person'
require 'models/person_model'

require 'json'

if ActiveSupport::TestCase.respond_to?(:test_order=)
  # TODO: remove check once ActiveSupport dependency is at least 4.2
  ActiveSupport::TestCase.test_order = :random
end

GlobalID.app = 'bcx'

# Default serializers is Marshal, whose format changed 1.9 -> 2.0,
# so use a trivial serializer for our tests.
SERIALIZER = JSON

VERIFIER = ActiveSupport::MessageVerifier.new('muchSECRETsoHIDDEN', serializer: SERIALIZER)
SignedGlobalID.verifier = VERIFIER

# activesupport/lib/active_support/testing/time_helpers isn't available in Rails 3
def travel(duration, &block)
  travel_to Time.now + duration, &block
end

def travel_to(date_or_time, &block)
  if date_or_time.is_a?(Date) && !date_or_time.is_a?(DateTime)
    now = date_or_time.midnight.to_time
  else
    now = date_or_time.to_time
  end

  simple_stubs.stub_object(Time, :now, now)
  simple_stubs.stub_object(Date, :today, now.to_date)

  if block_given?
    begin
      block.call
    ensure
      travel_back
    end
  end
end

def travel_back
  simple_stubs.unstub_all!
end

def simple_stubs
  @simple_stubs ||= SimpleStubs.new
end

class SimpleStubs # :nodoc:
  Stub = Struct.new(:object, :method_name, :original_method)

  def initialize
    @stubs = {}
  end

  def stub_object(object, method_name, return_value)
    key = [object.object_id, method_name]

    if stub = @stubs[key]
      unstub_object(stub)
    end

    new_name = "__simple_stub__#{method_name}"

    @stubs[key] = Stub.new(object, method_name, new_name)

    object.singleton_class.send :alias_method, new_name, method_name
    object.define_singleton_method(method_name) { return_value }
  end

  def unstub_all!
    @stubs.each_value do |stub|
      unstub_object(stub)
    end
    @stubs = {}
  end

  private

    def unstub_object(stub)
      singleton_class = stub.object.singleton_class
      singleton_class.send :undef_method, stub.method_name
      singleton_class.send :alias_method, stub.method_name, stub.original_method
      singleton_class.send :undef_method, stub.original_method
    end
end
