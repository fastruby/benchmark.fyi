class ReportsController < ApplicationController
  before_action :fix_missing_json_content_type

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

  # benchmark-ips sends the JSON string in the request body but it does not specify a content type
  # when that happens, Rails parses it incorrectly and produces a params key `"{\"entries\":"`
  # 
  # we can detect this and fix the params object to properly parse the request body as JSON and update
  # the `params` object
  def fix_missing_json_content_type
    if params.keys.include?("{\"entries\":") && request.body.present?
      begin
        json = JSON.parse(request.body.read)
        params.delete("{\"entries\":")
        params.merge!(json)
      rescue JSON::ParserError
        # Body was not valid JSON, do nothing
      ensure
        request.body.rewind
      end
    end
  end
end
