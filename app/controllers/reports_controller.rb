class ReportsController < ApplicationController
  wrap_parameters false

  include ReportsHelper

  protect_from_forgery :except => [:create]

  def create
    rep = Report.create! report_params

    options = params["options"] || {}

    if options["compare"]
      rep.compare = true
    end

    rep.save

    render json: { id: rep.short_id }
  rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid
    head 400
  end

  def show
    @report = Report.find_from_short_id params[:id]

    fastest = nil
    fastest_val = nil
    note_high_stddev = false

    @report.entries.each do |part|
      if !fastest_val || part["ips"] > fastest_val
        fastest = part
        fastest_val = part["ips"]
      end

      if stddev_percentage(part) >= 5
        note_high_stddev = true
      end
    end

    @note_high_stddev = note_high_stddev
    @fastest = fastest
  end

  private
  def report_params
    entries_params = params.require(:entries).map do |entry|
      entry.permit(:name, :ips, :central_tendency, :error, :stddev, :microseconds, :iterations, :cycles)
    end
    params.permit(:ruby, :os, :arch).merge(report: entries_params)
  end
end
