module ReportsHelper
  def format_ips(value)
    scale = (Math.log10(value) / 3).to_i
    suffix = case scale
             when 1; 'k'
             when 2; 'M'
             when 3; 'B'
             when 4; 'T'
             when 5; 'Q'
             else
               # < 1000 or > 10^15, no scale or suffix
               scale = 0
               ' '
             end
    "%10.3f#{suffix}" % (value.to_f / (1000 ** scale))
  end

  def times_slower(best, cur)
    best_low = best["ips"] - best["stddev"]
    report_high = cur["ips"] + cur["stddev"]
    overlaps = report_high > best_low

    if overlaps
      return "-"
    else
      "%.2fx" % (best["ips"] / cur["ips"])
    end
  end

  def stddev_percentage(part)
    100.0 * (part["stddev"] / part["ips"])
  end

  def format_stddev(part)
    "%4.1f%%" % stddev_percentage(part)
  end

  # The report rendered as a markdown table, for pasting into an issue or a
  # pull request. Mirrors what the page shows: the fastest entry is bolded and
  # the slower column only appears for comparison reports.
  def report_markdown(report, fastest, url)
    columns = ["name", "iterations/second"]
    columns << "slower" if report.compare

    lines = []
    lines << "| #{columns.join(" | ")} |"
    lines << "| #{columns.map { "---" }.join(" | ")} |"

    report.entries.each do |entry|
      name = markdown_cell(entry["name"])
      name = "**#{name}**" if fastest && entry["name"] == fastest["name"]

      cells = [name, "#{format_ips(entry["ips"]).strip} \u00b1 #{format_stddev(entry).strip}"]
      cells << times_slower(fastest, entry) if report.compare

      lines << "| #{cells.join(" | ")} |"
    end

    environment = report_environment(report)
    lines << ""
    lines << [environment, "Full report: #{url}"].compact.join(". ")

    lines.join("\n")
  end

  # "interpolation and 3 others - benchmark.fyi". A single-entry report gets just
  # the name, since "and 0 others" reads like a bug.
  def report_title(report, fastest)
    name = fastest ? fastest["name"] : "Report"
    others = report.entries.size - 1
    name = "#{name} and #{pluralize(others, "other")}" if others.positive?

    "#{name} - benchmark.fyi"
  end

  # Benchmark names are arbitrary strings. An unescaped pipe would add a column
  # to the markdown table and break the row for everyone who pastes it.
  def markdown_cell(value)
    value.to_s.gsub("|") { "\\|" }
  end

  # "ruby 4.0.6, darwin/arm64" from whichever of those fields the client sent.
  # Older reports predate them entirely, so this can be nil.
  def report_environment(report)
    ruby = "ruby #{report.ruby}" if report.ruby.present?
    machine = [report.os, report.arch].reject(&:blank?).join("/")

    parts = [ruby, machine.presence].compact
    parts.any? ? parts.join(", ") : nil
  end
end
