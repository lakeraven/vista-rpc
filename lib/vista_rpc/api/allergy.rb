# frozen_string_literal: true

module VistaRpc
  # Symbolic API for allergy reads against stock VistA (ORQQAL LIST).
  module Allergy
    extend self

    def for_patient(dfn)
      rows = DataMapper.allergy_list.fetch_many(dfn.to_s)
      # LIST^ORQQAL signals "^No Allergy Assessment", "^No Known Allergies",
      # and "^No allergies found." with sentinel rows whose IEN piece is
      # blank; don't surface them as allergy records. Real file #120.8 IENs
      # are always positive.
      rows.reject { |r| r[:allergy_ien].to_i <= 0 }
    end
  end
end
