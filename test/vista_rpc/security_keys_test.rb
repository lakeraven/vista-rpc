# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/vista_rpc/security_keys"

class VistaRpc::SecurityKeysTest < Minitest::Test
  def test_symbolize_known_keys
    result = VistaRpc::SecurityKeys.symbolize([ "PRCFA SUPERVISOR", "GMRC MGR" ])
    assert_equal [ :prc_supervisor, :consult_manager ], result
  end

  def test_symbolize_ignores_unknown_keys
    result = VistaRpc::SecurityKeys.symbolize([ "PRCFA SUPERVISOR", "UNKNOWN KEY", "OR CPRS GUI CHART" ])
    assert_equal [ :prc_supervisor, :cprs_gui_chart ], result
  end

  def test_symbolize_empty
    assert_equal [], VistaRpc::SecurityKeys.symbolize([])
  end

  def test_symbolize_nil
    assert_equal [], VistaRpc::SecurityKeys.symbolize(nil)
  end

  def test_rpms_name
    assert_equal "PRCFA SUPERVISOR", VistaRpc::SecurityKeys.rpms_name(:prc_supervisor)
    assert_equal "GMRC MGR", VistaRpc::SecurityKeys.rpms_name(:consult_manager)
    assert_nil VistaRpc::SecurityKeys.rpms_name(:nonexistent)
  end

  def test_registry_is_frozen
    assert VistaRpc::SecurityKeys::REGISTRY.frozen?
  end
end
