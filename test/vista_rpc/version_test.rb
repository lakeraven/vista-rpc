# frozen_string_literal: true

require "test_helper"

class VistaRpcVersionTest < Minitest::Test
  def test_version_is_defined
    refute_nil VistaRpc::VERSION
  end

  def test_configure_yields_configuration
    VistaRpc.reset!
    yielded = nil
    VistaRpc.configure { |c| yielded = c }
    assert_instance_of VistaRpc::Configuration, yielded
  end

  def test_client_raises_when_unconfigured
    VistaRpc.reset!
    assert_raises(VistaRpc::NotConfiguredError) { VistaRpc.client }
  end
end
