# frozen_string_literal: true

module VistaRpc
  # Symbolic API for VistA vitals reads.
  module Vital
    module_function

    def for_patient(dfn)
      DataMapper.vitals.fetch_many(dfn.to_s)
    end
  end
end
