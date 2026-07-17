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

  # Wire rows verified live on VEHU (DFN 100022):
  # ITEMS:    63^3^^HGB^^3150603.1454^10^lab - HEMATOLOGY^HE
  # ITEMDATA: 63^3^3150603.1454^^6.0^L^70^BLOOD^^14!18^g/dL
  def test_lab_graph_items
    results = VistaRpc::DataMapper[:lab_graph_items].parse_many([
      "63^3^^HGB^^3150603.1454^10^lab - HEMATOLOGY^HE"
    ])

    assert_equal 1, results.size
    assert_equal 3, results[0][:test_ien]
    assert_equal "HGB", results[0][:test_name]
    assert_equal "lab - HEMATOLOGY", results[0][:display_group]
    assert results[0][:newest_result].is_a?(Time)
  end

  def test_lab_graph_data
    results = VistaRpc::DataMapper[:lab_graph_data].parse_many([
      "63^3^3150603.1454^^6.0^L^70^BLOOD^^14!18^g/dL"
    ])

    assert_equal 1, results.size
    assert_equal 3, results[0][:test_ien]
    assert_equal "6.0", results[0][:result]
    assert_equal "L", results[0][:abnormal_flag]
    assert_equal "BLOOD", results[0][:specimen]
    assert_equal "14!18", results[0][:reference_range]
    assert_equal "g/dL", results[0][:units]

    result_time = results[0][:collection_date]
    assert result_time.is_a?(Time)
    assert_equal 2015, result_time.year
    assert_equal 6, result_time.month
    assert_equal 3, result_time.day
    assert_equal 14, result_time.hour
    assert_equal 54, result_time.min
  end

  def test_lab_report_list
    results = VistaRpc::DataMapper[:lab_report_list].parse_many([
      "CBC PROFILE^Cbc Profile ^Y^N^80",
      "MICROBIOLOGY^Microbiology ^Y^N^80"
    ])

    assert_equal 2, results.size
    assert_equal "CBC PROFILE",   results[0][:report_id]
    assert_equal "Cbc Profile ", results[0][:report_name]
    assert_equal "Y",            results[0][:enabled_flag]
    assert_equal "N",            results[0][:requires_date_flag]
    assert_equal 80,             results[0][:max_occurrences]
  end

  def test_lab_report_text_blob
    m = VistaRpc::DataMapper[:lab_report]
    text = m.parse_text([
      "GLUCOSE: 95 mg/dL (Reference: 70-100)",
      "POTASSIUM: 4.2 mEq/L (Reference: 3.5-5.0)",
      "---"
    ])

    assert_equal "GLUCOSE: 95 mg/dL (Reference: 70-100)\nPOTASSIUM: 4.2 mEq/L (Reference: 3.5-5.0)\n---", text
  end

  # Wire order verified against LIST^ORQQAL and live VEHU rows:
  # ALLERGY_IEN^ALLERGEN^SEVERITY^REACTIONS ("; "-joined symptoms).
  def test_allergy_list
    results = VistaRpc::DataMapper[:allergy_list].parse_many([ "42^PENICILLIN^MODERATE^RASH", "7^ASPIRIN^SEVERE^HIVES; ANOREXIA" ])
    assert_equal 2, results.size
    assert_equal 42, results[0][:allergy_ien]
    assert_equal "PENICILLIN", results[0][:allergen]
    assert_equal "RASH", results[0][:reaction]
    assert_equal "SEVERE", results[1][:severity]
    assert_equal 7, results[1][:allergy_ien]
    assert_equal "HIVES; ANOREXIA", results[1][:reaction]
  end

  def test_allergy_detail
    result = VistaRpc::DataMapper[:allergy_detail].parse_one(
      "PENICILLIN^PROVIDER,ONE^PHYSICIAN^VERIFIED^OBSERVED^^DRUG^3150115^MODERATE^PENICILLINS^RASH;HIVES^No comments"
    )
    assert_equal "PENICILLIN", result[:allergen]
    assert_equal "PROVIDER,ONE", result[:originator]
    assert_equal "PHYSICIAN", result[:originator_title]
    assert_equal "VERIFIED", result[:verification_status]
    assert_equal "OBSERVED", result[:observed_historical]
    assert_equal "DRUG", result[:type]
    assert_equal Date.new(2015, 1, 15), result[:observation_date]
    assert_equal "MODERATE", result[:severity]
    assert_equal "PENICILLINS", result[:drug_class]
    assert_equal "RASH;HIVES", result[:symptoms]
    assert_equal "No comments", result[:comments]
  end

  def test_consult_list
    results = VistaRpc::DataMapper[:consult_list].parse_many([
      "123^3150115.0830^PENDING^Cardiology^Echocardiogram",
      "456^3150116.0900^ACTIVE^Orthopedics^Knee MRI"
    ])

    assert_equal 2, results.size
    assert_equal 123, results[0][:ien]
    assert results[0][:request_date].is_a?(Time)
    assert_equal 2015, results[0][:request_date].year
    assert_equal 1, results[0][:request_date].month
    assert_equal 15, results[0][:request_date].day
    assert_equal 8, results[0][:request_date].hour
    assert_equal 30, results[0][:request_date].min
    assert_equal "PENDING", results[0][:status]
    assert_equal "Cardiology", results[0][:consulting_service]
    assert_equal "Echocardiogram", results[0][:procedure]
  end

  def test_consult_detail
    result = VistaRpc::DataMapper[:consult_detail].parse_one(
      "3150115^1^100000001^^^^^123.5^44^3150115.0830^GMRCOR REQUEST^1^1^7^1^8^10;PROVIDER,ONE^123^C^P^I^U^8925^3150115.0900"
    )

    assert_equal Date.new(2015, 1, 15), result[:entry_date]
    assert_equal 1, result[:patient_dfn]
    assert_equal "123.5", result[:to_service]
    assert_equal Date.new(2015, 1, 15), result[:request_date]
    assert_equal "GMRCOR REQUEST", result[:procedure_type]
    assert_equal "1", result[:cprs_status]
    assert_equal "10;PROVIDER,ONE", result[:sending_provider]
    assert_equal "P", result[:request_type]
    assert_equal Date.new(2015, 1, 15), result[:clinically_indicated_date]
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
      patient_appointments allergy_list allergy_detail problem_list vitals
      practitioner_info practitioner_list user_management_user_list
      medication_list care_plan_list care_team_list goal_list
      procedure_list device_list lab_interim_report lab_graph_items
      lab_graph_data radiology_list
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
      consult_list consult_detail
      symptom_search symptom_defaults
      image_exams
    ]

    expected.each do |name|
      assert VistaRpc::DataMapper[name], "Missing stock VistA mapping: #{name}"
      assert_equal "VistaRpc::DataMapper::Mapping", VistaRpc::DataMapper[name].class.name
    end
  end
end
