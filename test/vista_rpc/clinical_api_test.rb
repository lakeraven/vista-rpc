# frozen_string_literal: true

require 'test_helper'

class ClinicalApiTest < Minitest::Test
  class FakeClient
    attr_reader :calls

    def initialize(responses)
      @responses = responses
      @calls = []
    end

    def call_rpc(rpc_name, *params)
      @calls << { rpc: rpc_name, params: params }
      Array(@responses.fetch(rpc_name, []))
    end
  end

  def setup
    @original_client = VistaRpc.configuration.client
  end

  def teardown
    VistaRpc.configure { |c| c.client = @original_client }
  end

  def test_vital_for_patient_fetches_vitals_mapping
    client = with_client('ORQQVI VITALS' => ['BP^120/80^mm[Hg]^3250115', 'P^72^/min^3250115'])
    results = VistaRpc::Vital.for_patient(1)

    assert_equal 2, results.length
    assert_equal 'BP', results.first[:type]
    assert_equal Date.new(2025, 1, 15), results.first[:recorded_date]
    assert_equal({ rpc: 'ORQQVI VITALS', params: ['1'] }, client.calls.first)
  end

  def test_lab_for_patient_enumerates_items_then_fetches_datapoints
    client = with_client(
      'ORWGRPC ITEMS' => ["63^3^^HGB^^#{recent_fm_datetime}^10^lab - HEMATOLOGY^HE"],
      'ORWGRPC ITEMDATA' => ["63^3^#{recent_fm_datetime}^^6.0^L^70^BLOOD^^14!18^g/dL"]
    )
    results = VistaRpc::Lab.for_patient(1)

    assert_equal({ rpc: 'ORWGRPC ITEMS', params: %w[1 63] }, client.calls.first)
    data_call = client.calls.last
    assert_equal 'ORWGRPC ITEMDATA', data_call[:rpc]
    assert_equal '63^3', data_call[:params][0]
    assert_match(/\A\d{7}\z/, data_call[:params][1])
    assert_equal '1', data_call[:params][2]

    assert_equal 1, results.length
    assert_equal 'HGB', results.first[:test_name]
    assert_equal '6.0', results.first[:result]
    assert_equal 'g/dL', results.first[:units]
    assert_equal '14 - 18', results.first[:reference_range]
    assert_equal 'final', results.first[:status]
  end

  def test_lab_for_patient_decorates_abnormal_results
    with_client(
      'ORWGRPC ITEMS' => ["63^3^^HGB^^#{recent_fm_datetime}^10^lab - HEMATOLOGY^HE"],
      'ORWGRPC ITEMDATA' => [
        "63^3^#{recent_fm_datetime}^^13.5^N^70^BLOOD^^12.0!15.5^g/dL",
        "63^3^#{recent_fm_datetime}^^7.2^H^70^BLOOD^^!^%"
      ]
    )
    results = VistaRpc::Lab.for_patient(1)

    assert_equal([false, true], results.map { |r| r[:abnormal] })
    assert_nil results.last[:reference_range]
  end

  def test_lab_for_patient_filters_datapoints_outside_the_window
    with_client(
      'ORWGRPC ITEMS' => ["63^3^^HGB^^#{recent_fm_datetime}^10^lab - HEMATOLOGY^HE"],
      'ORWGRPC ITEMDATA' => ["63^3^3010101.0800^^6.0^L^70^BLOOD^^14!18^g/dL"]
    )

    assert_equal [], VistaRpc::Lab.for_patient(1, days: 90)
  end

  def test_lab_for_patient_returns_empty_for_invalid_dfn
    with_client({})

    assert_equal [], VistaRpc::Lab.for_patient(nil)
    assert_equal [], VistaRpc::Lab.for_patient('')
    assert_equal [], VistaRpc::Lab.for_patient(0)
  end

  # Wire row verified live on VEHU (DFN 100001):
  # 733^Hypertension (ICD-9-CM 401.9)^A^401.9^3050407^3070410^NSC^...
  def test_problem_for_patient_sends_status_param_and_parses_rows
    client = with_client('ORQQPL LIST' => ['733^Hypertension^A^401.9^3050407^3070410^NSC'])
    results = VistaRpc::Problem.for_patient(100_001)

    assert_equal({ rpc: 'ORQQPL LIST', params: ['100001', ''] }, client.calls.first)
    assert_equal 1, results.length
    assert_equal '733', results.first[:ien]
    assert_equal 'Hypertension', results.first[:description]
    assert_equal 'A', results.first[:status]
    assert_equal '401.9', results.first[:icd_code]
    assert_equal 'NSC', results.first[:service_connected]
  end

  def test_problem_for_patient_maps_status_keyword
    client = with_client('ORQQPL LIST' => [])
    VistaRpc::Problem.for_patient(1, status: :active)

    assert_equal ['1', 'A'], client.calls.first[:params]
  end

  def test_problem_for_patient_rejects_unknown_status
    with_client({})

    assert_raises(ArgumentError) { VistaRpc::Problem.for_patient(1, status: :bogus) }
  end

  def test_problem_for_patient_filters_no_problems_sentinel
    with_client('ORQQPL LIST' => ['^No problems found.'])

    assert_equal [], VistaRpc::Problem.for_patient(1)
  end

  # Wire row verified live on VEHU (DFN 100022):
  # 971^ERYTHROMYCIN^MODERATE^ANOREXIA; DIARRHEA; DROWSINESS; HIVES
  def test_allergy_for_patient_fetches_allergy_list_mapping
    client = with_client('ORQQAL LIST' => ['701^PENICILLIN^MODERATE^HIVES; ANOREXIA'])
    results = VistaRpc::Allergy.for_patient(1)

    assert_equal({ rpc: 'ORQQAL LIST', params: ['1'] }, client.calls.first)
    assert_equal 701, results.first[:allergy_ien]
    assert_equal 'PENICILLIN', results.first[:allergen]
    assert_equal 'MODERATE', results.first[:severity]
    assert_equal 'HIVES; ANOREXIA', results.first[:reaction]
  end

  def test_allergy_for_patient_filters_sentinel_rows
    with_client('ORQQAL LIST' => ['^No Allergy Assessment'])

    assert_equal [], VistaRpc::Allergy.for_patient(1)
  end

  private

  # FileMan datetime a few days back, so fixtures stay inside default windows.
  def recent_fm_datetime
    date = Date.today - 3
    format('%d%02d%02d.0800', date.year - 1700, date.month, date.day)
  end

  def with_client(responses)
    FakeClient.new(responses).tap do |client|
      VistaRpc.configure { |c| c.client = client }
    end
  end
end
