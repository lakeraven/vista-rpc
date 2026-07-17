# frozen_string_literal: true

require 'date'

module VistaRpc
  # Symbolic API for VistA laboratory result reads.
  #
  # Structured results come from the CPRS graphing RPCs (ORWGRPC ITEMS +
  # ORWGRPC ITEMDATA over the ^PXRMINDX(63) verified-results index) — the
  # only context-registered RPC pair on stock VistA that returns lab results
  # as delimited records. ORWLRR INTERIM returns a human-readable report and
  # is exposed separately as `interim_report`.
  module Lab
    module_function

    # Recent labs for a patient. Defaults to the last 90 days.
    # Returns an Array of result hashes (empty for invalid/unknown DFN):
    #   { ien:, test_name:, result:, units:, reference_range:,
    #     abnormal:, abnormal_flag:, collection_date:, status:, specimen: }
    def for_patient(dfn, days: 90)
      return [] if blank?(dfn) || dfn.to_i <= 0

      cutoff = Date.today - days
      # ITEMDATA iterates backward from START; tomorrow's date returns
      # everything up to now.
      start = FilemanDateParser.format_date(Date.today + 1)

      items = DataMapper.lab_graph_items.fetch_many(dfn.to_s, '63')
      items.flat_map do |item|
        rows = DataMapper.lab_graph_data.fetch_many("63^#{item[:test_ien]}", start, dfn.to_s)
        rows.filter_map do |row|
          collected = row[:collection_date]
          next if collected && collected.to_date < cutoff

          build_result(item, row)
        end
      end
    end

    def abnormal(dfn, days: 90)
      for_patient(dfn, days: days).select { |r| r[:abnormal] }
    end

    # Human-readable interim report text (ORWLRR INTERIM). SELECT^LR7OGM
    # takes its date range most-recent-first, so the recent date goes first —
    # forward order silently returns "No Data Found".
    def interim_report(dfn, days: 90)
      return nil if blank?(dfn) || dfn.to_i <= 0

      recent = FilemanDateParser.format_date(Date.today)
      oldest = FilemanDateParser.format_date(Date.today - days)
      DataMapper.lab_interim_report.fetch_text(dfn.to_s, recent, oldest)
    end

    class << self
      private

      # Compose an ITEMS row (test identity) with an ITEMDATA row (datapoint)
      # into the flat shape downstream FHIR adapters consume.
      def build_result(item, row)
        flag = row[:abnormal_flag]
        {
          ien: "#{row[:test_ien]};#{row[:collection_date]&.strftime('%Y%m%d%H%M%S')}",
          test_name: item[:test_name],
          result: row[:result],
          units: row[:units],
          reference_range: format_range(row[:reference_range]),
          abnormal_flag: flag,
          abnormal: !blank?(flag) && flag.to_s.upcase != 'N',
          collection_date: row[:collection_date],
          # ^PXRMINDX(63) only indexes verified results.
          status: 'final',
          specimen: row[:specimen]
        }
      end

      # Wire ref range is "LO!HI"; render the human form the reports show.
      def format_range(range)
        return nil if blank?(range)

        lo, hi = range.to_s.split('!', 2)
        formatted = [lo, hi].reject { |p| blank?(p) }.join(' - ')
        blank?(formatted) ? nil : formatted
      end

      def blank?(val)
        val.nil? || val.to_s.empty?
      end
    end
  end
end
