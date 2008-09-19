require File.expand_path(File.join(File.dirname(__FILE__),'/../../../../../test/test_helper'))
require "test/unit"
require "mocha"
require 'newrelic/local_environment'
class EnvironmentTest < ActiveSupport::TestCase
  
  def teardown
    # To remove mock server instances from ObjectSpace
    ObjectSpace.garbage_collect
    super
  end
  class MockOptions
    def fetch (*args)
      1000
    end
  end
  MOCK_OPTIONS = MockOptions.new
  
  def test_environment
    e = NewRelic::LocalEnvironment.new
    assert_equal :unknown, e.environment
    assert_nil e.identifier
  end
  def test_webrick
    class << self
      ::OPTIONS=MockOptions.new
      ::DEFAULT_PORT=5000
    end
    e = NewRelic::LocalEnvironment.new
    assert_equal :webrick, e.environment
    assert_equal 1000, e.identifier
    Object.class_eval { remove_const :OPTIONS }
    Object.class_eval { remove_const :DEFAULT_PORT }
  end
  def test_no_webrick
    class << self
      ::OPTIONS='foo'
      ::DEFAULT_PORT=5000
    end
    e = NewRelic::LocalEnvironment.new
    assert_equal :unknown, e.environment
    assert_nil e.identifier
    Object.class_eval { remove_const :OPTIONS }
    Object.class_eval { remove_const :DEFAULT_PORT }
  end
  def test_mongrel
    require 'mongrel'
    m = Mongrel::HttpServer.new('127.0.0.1',3030)
    e = NewRelic::LocalEnvironment.new
    assert_equal :mongrel, e.environment
    assert_equal 3030, e.identifier
  end
  def test_thin
    class << self
      module ::Thin
        class Server
          def backend; self; end
          def socket; "/socket/file.000"; end
        end
      end
    end
    mock_thin = Thin::Server.new
    e = NewRelic::LocalEnvironment.new
    assert_equal :thin, e.environment
    assert_equal '/socket/file.000', e.identifier
    mock_thin
  end
  def test_litespeed
    e = NewRelic::LocalEnvironment.new
    assert_equal :unknown, e.environment
    assert_nil e.identifier
  end
  def test_passenger
    class << self
      module ::Passenger
        const_set "AbstractServer", 0
      end
    end
    e = NewRelic::LocalEnvironment.new
    assert_equal :passenger, e.environment
    assert_equal 'passenger', e.identifier
    ::Passenger.class_eval { remove_const :AbstractServer }
  end
  def test_daemon
    NewRelic::LocalEnvironment.any_instance.expects(:config).returns('foo.rb')
    e = NewRelic::LocalEnvironment.new
    assert_equal :daemon, e.environment
    assert_not_nil e.identifier
  end
end