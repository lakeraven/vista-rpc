# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/vista_rpc/user_roles"

class VistaRpc::UserRolesTest < Minitest::Test
  def test_for_class_maps_known_classes
    assert_equal "provider", VistaRpc::UserRoles.for_class("3")
    assert_equal "nurse", VistaRpc::UserRoles.for_class("4")
    assert_equal "clerk", VistaRpc::UserRoles.for_class("5")
    assert_equal "admin", VistaRpc::UserRoles.for_class("1")
  end

  def test_for_class_defaults_to_user
    assert_equal "user", VistaRpc::UserRoles.for_class("99")
    assert_equal "user", VistaRpc::UserRoles.for_class("")
  end

  def test_for_class_accepts_integer
    assert_equal "nurse", VistaRpc::UserRoles.for_class(4)
  end

  def test_resolve_provider_from_av_code_class
    assert_equal "provider", VistaRpc::UserRoles.resolve(
      user_class: "3", security_keys: []
    )
  end

  def test_resolve_case_manager_from_security_key_elevation
    # prc_supervisor elevates beyond whatever user_class would yield.
    assert_equal "case_manager", VistaRpc::UserRoles.resolve(
      user_class: "3", security_keys: [ :prc_supervisor ]
    )
    assert_equal "case_manager", VistaRpc::UserRoles.resolve(
      user_class: "4", security_keys: [ :prc_manager ]
    )
  end

  def test_resolve_nurse_from_class
    assert_equal "nurse", VistaRpc::UserRoles.resolve(
      user_class: "4", security_keys: []
    )
  end

  def test_resolve_defaults_to_user_when_class_unknown_blank_or_nil
    assert_equal "user", VistaRpc::UserRoles.resolve(
      user_class: nil, security_keys: []
    )
    assert_equal "user", VistaRpc::UserRoles.resolve(
      user_class: "", security_keys: []
    )
    assert_equal "user", VistaRpc::UserRoles.resolve(
      user_class: "99", security_keys: []
    )
  end
end
