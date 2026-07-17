# frozen_string_literal: true

require 'date'

module VistaRpc
  # Symbolic API for VistA laboratory result reads.
  module Lab
    module_function

    def for_patient(dfn, days: 90)
      return [] if blank?(dfn) || dfn.to_i <= 0

      from_date, to_date = date_window(days)
      raw = DataMapper.lab_result_list.fetch_many(dfn.to_s, from_date, to_date)
      Array(raw).map { |row| decorate_result(row) }
    end

    def abnormal(dfn, days: 90)
      for_patient(dfn, days: days).select { |r| r[:abnormal] }
    end

    def build_list_param(dfn, days = 90)
      date_window(days, dfn: dfn)
    end

    class << self
      private

      def date_window(days, dfn: nil)
        to_date = Date.today
        from_date = to_date - days
        [
          dfn.to_s,
          FilemanDateParser.format_date(from_date),
          FilemanDateParser.format_date(to_date)
        ].tap { |a| a.shift if dfn.nil? }
      end

      def decorate_result(row)
        flag = row[:abnormal_flag]
        row.merge(abnormal: !blank?(flag) && flag.to_s.upcase != 'N')
      end

      def blank?(val)
        val.nil? || val.to_s.empty?
      end
    end
  end
end
