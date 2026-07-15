# frozen_string_literal: true

require "minitest/autorun"
require "date"
require "vista_rpc/mappings"

class VistaRpc::MappingsTest < Minitest::Test
  def test_patient_select_parses_full_response
    m = VistaRpc::DataMapper[:patient_select]
    result = m.parse_one("DOE,JOHN^M^2800115^111223333^^^^^^^^^^^45", extras: { dfn: 1 })

    assert_equal 1, result[:dfn]
    assert_equal "DOE,JOHN", result[:name]
    assert_equal "M", result[:sex]
    assert_equal Date.new(1980, 1, 15), result[:dob]
    assert_equal "111223333", result[:ssn]
    assert_equal 45, result[:age]
  end

  def test_allergy_list
    results = VistaRpc::DataMapper[:allergy_list].parse_many([ "PENICILLIN^RASH^MODERATE", "ASPIRIN^HIVES^SEVERE" ])
    assert_equal 2, results.size
    assert_equal "PENICILLIN", results[0][:allergen]
    assert_equal "SEVERE", results[1][:severity]
  end

  def test_practitioner_info
    result = VistaRpc::DataMapper[:practitioner_info].parse_one(
      "1^PROVIDER,TEST^3^1^1^5^0^99999^20^1^1^5^DEMO.IHS.GOV^0^180^^^^0^0^^1^0^8904^"
    )
    assert_equal 1, result[:duz]
    assert_equal "PROVIDER,TEST", result[:name]
    assert_equal 8904, result[:site_ien]
  end

  def test_report_text_blob
    m = VistaRpc::DataMapper[:report_text]
    text = m.parse_text([ "Patient: DOE,JOHN", "Date: 2025-03-15", "Vitals normal." ])
    assert_equal "Patient: DOE,JOHN\nDate: 2025-03-15\nVitals normal.", text
  end

  def test_stock_vista_mappings_registered
    expected = %i[
      patient_select patient_id_info patient_list patient_ssn
      patient_appointments allergy_list problem_list vitals
      practitioner_info practitioner_list user_management_user_list
      medication_list care_plan_list care_team_list goal_list
      procedure_list device_list lab_result_list radiology_list
      user_info mailman_message mailman_messages_for_patient mailman_send
      mailman_reply mailman_thread mailman_inbox xqal_alert xqal_mark_read
      xqal_forward report_types reminders_list
      reminder_detail patient_deceased patient_sensitive user_has_key
      signon_setup av_code cvc_verify user_keys
      report_text report_type_components health_summary_report
      flowsheet_list flowsheet_data maint_items lab_report lab_report_list radiology_report
      medication_detail care_plan_detail care_team_detail goal_detail
      procedure_detail device_detail patient_recent patient_save_recent
      key_list key_grant key_revoke
      prescription_new erx_status prescription_cancel
      tiu_create_record tiu_documents_by_context tiu_get_record_text
      tiu_authorization tiu_lock_record tiu_unlock_record tiu_set_document_text
      tiu_valid_signature tiu_sign_record tiu_which_signature_action
      template_roots template_items template_boilerplate template_text template_access_level
      orders_unsigned orders_list order_result order_result_history
      order_action_text order_expired order_sheets order_sheets_all
      symptom_search symptom_defaults
      image_exams
    ]

    expected.each do |name|
      assert VistaRpc::DataMapper[name], "Missing stock VistA mapping: #{name}"
      assert_equal "VistaRpc::DataMapper::Mapping", VistaRpc::DataMapper[name].class.name
    end
  end
end
