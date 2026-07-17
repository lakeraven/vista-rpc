# frozen_string_literal: true

module VistaRpc
  # Symbolic API for problem-list reads against stock VistA (ORQQPL LIST).
  # IHS-specific problem writes (BGOPROB*) stay in RpmsRpc::Problem.
  module Problem
    extend self

    # ORQQPL LIST status codes (LIST^ORQQPL: STATUS param). The param is
    # required on the wire — omitting it raises the M error
    # "Undefined local variable: STATUS".
    LIST_STATUS_CODES = {
      all: "",
      active: "A",
      inactive: "I"
    }.freeze

    def for_patient(dfn, status: :all)
      code = LIST_STATUS_CODES.fetch(status) do
        raise ArgumentError, "unknown status: #{status.inspect}"
      end
      rows = DataMapper.problem_list.fetch_many(dfn.to_s, code)
      # LIST^ORQQPL signals empty ("^No problems found.") or unavailable
      # ("^Problem list not available.^") with a sentinel row whose IEN piece
      # is blank; don't surface it as a problem record.
      rows.reject { |r| r[:ien].to_s.empty? }
    end
  end
end
