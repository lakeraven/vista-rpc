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

  def test_lab_for_patient_sends_three_separate_params
    client = with_client('ORWLRR INTERIM' => [])
    VistaRpc::Lab.for_patient(1)

    assert_lab_interim_call(client.calls.first)
  end

  def test_lab_for_patient_decorates_abnormal_results
    with_client('ORWLRR INTERIM' => [
                  '9001^718-7^13.5^g/dL^12.0-15.5^N^3250114.0830^final',
                  '9002^2093-3^7.2^%^<5.7^H^3250114.0900^final'
                ])
    results = VistaRpc::Lab.for_patient(1)

    assert_equal([false, true], results.map { |r| r[:abnormal] })
  end

  def test_lab_for_patient_returns_empty_for_invalid_dfn
    with_client({})

    assert_equal [], VistaRpc::Lab.for_patient(nil)
    assert_equal [], VistaRpc::Lab.for_patient('')
    assert_equal [], VistaRpc::Lab.for_patient(0)
  end

  private

  def assert_lab_interim_call(call)
    params = call[:params]
    assert_equal 'ORWLRR INTERIM', call[:rpc]
    assert_equal 3, params.length
    assert_equal '1', params[0]
    params[1..].each { |date| assert_match(/\A\d{7}\z/, date) }
  end

  def with_client(responses)
    FakeClient.new(responses).tap do |client|
      VistaRpc.configure { |c| c.client = client }
    end
  end
end
