#!/usr/bin/env ruby

require "date"
require "digest"
require "fileutils"
require "json"
require "net/http"
require "optparse"
require "time"
require "uri"
require "yaml"

# Observes availability and HTTP version markers for the official sources that
# underpin the regulatory horizon. It deliberately does not interpret legal
# changes and never changes an approval decision. A reviewer must compare a
# generated snapshot with the last reviewed source state before changing any
# source or release-evidence declaration.
class ComplianceSourceObserver
  USER_AGENT = "ScanFair-ComplianceSourceObserver/1.0 (+manual-review-required)".freeze
  CONTENT_SAMPLE_BYTES = 131_072

  attr_reader :report

  def initialize(repo_root:, report_path: ".quality/compliance-horizon/source-observation.json", baseline_path: "docs/project/compliance/source-observation-baseline.yaml", offline: false, now: Time.now.utc)
    @repo_root = File.expand_path(repo_root)
    @report_path = report_path
    @baseline_path = baseline_path
    @offline = offline
    @now = now
    @baseline_sources = {}
  end

  def run
    sources = horizon_sources
    @baseline_sources = baseline_sources
    observations = sources.map { |source| observe(source) }
    @report = {
      "schema_version" => "1.0",
      "generated_at" => @now.iso8601,
      "mode" => @offline ? "offline" : "online",
      "baseline_path" => @baseline_path,
      "automatic_approval" => false,
      "manual_change_assessment" => {
        "required" => observations.any? { |observation| observation["manual_review_required"] },
        "reason" => "A changed, missing-baseline or unavailable source requires manual legal, claim and release-impact assessment. Observation alone never grants approval.",
      },
      "decision" => observations.any? { |observation| observation["manual_review_required"] } ? "REVIEW_REQUIRED" : "NO_CHANGE_OBSERVED",
      "sources" => observations,
    }
    write_report
    true
  end

  private

  def load_yaml(relative)
    YAML.safe_load(File.read(File.join(@repo_root, relative), encoding: "UTF-8"), permitted_classes: [Date, Time], aliases: true) || {}
  end

  def baseline_sources
    path = File.absolute_path(@baseline_path, @repo_root)
    return {} unless File.file?(path)

    baseline = YAML.safe_load(File.read(path, encoding: "UTF-8"), permitted_classes: [Date, Time], aliases: true) || {}
    Array(baseline["sources"]).to_h { |source| [source["id"], source] }
  rescue Psych::SyntaxError => error
    raise "invalid source-observation baseline: #{error.message.lines.first.strip}"
  end

  def horizon_sources
    horizon = load_yaml("docs/project/compliance/regulatory-horizon.yaml")
    registry = load_yaml("docs/project/compliance/source-register.yaml")
    indexed_sources = Array(registry["sources"]).to_h { |source| [source["id"], source] }
    source_ids = Array(horizon["controls"]).flat_map { |control| Array(control["source_refs"]) }.uniq.sort

    source_ids.map do |source_id|
      source = indexed_sources.fetch(source_id) do
        raise "regulatory horizon references missing source #{source_id}"
      end
      raise "source #{source_id} has no HTTPS URL" unless source["url"].to_s.start_with?("https://")

      source.slice("id", "authority", "title", "url", "version")
    end
  end

  def observe(source)
    return offline_observation(source) if @offline

    uri = URI.parse(source.fetch("url"))
    response = request(uri, Net::HTTP::Head)

    status_code = response.code.to_i
    headers = {
      "etag" => response["etag"],
      "last_modified" => response["last-modified"],
      "content_type" => response["content-type"],
      "location" => response["location"],
    }.compact
    content_marker = content_marker(uri)
    state_signature = Digest::SHA256.hexdigest(
      JSON.generate(source.merge("http_status" => status_code, "headers" => headers, "content_marker" => content_marker)),
    )
    comparison = comparison_for(source.fetch("id"), state_signature, content_marker)

    source.merge(
      "observation_status" => status_code.between?(200, 399) ? "reachable" : "http_unavailable",
      "http_status" => status_code,
      "headers" => headers,
      "content_marker" => content_marker,
      "state_signature" => state_signature,
      "automatic_approval" => false,
    ).merge(comparison)
  rescue StandardError => error
    source.merge(
      "observation_status" => "network_unavailable",
      "error_class" => error.class.name,
      "automatic_approval" => false,
      "manual_review_required" => true,
      "change_signal" => "observation_unavailable",
    )
  end

  def request(uri, request_class)
    request = request_class.new(uri)
    request["User-Agent"] = USER_AGENT
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 8,
      read_timeout: 8,
      write_timeout: 8,
    ) { |http| http.request(request) }
  end

  def content_marker(uri)
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT
    request["Range"] = "bytes=0-#{CONTENT_SAMPLE_BYTES - 1}"
    sample = +"".b
    status_code = nil
    content_type = nil
    content_range = nil
    truncated = false

    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 8,
      read_timeout: 8,
      write_timeout: 8,
    ) do |http|
      http.request(request) do |response|
        status_code = response.code.to_i
        content_type = response["content-type"]
        content_range = response["content-range"]
        response.read_body do |chunk|
          remaining = CONTENT_SAMPLE_BYTES - sample.bytesize
          if remaining.positive?
            sample << chunk.byteslice(0, remaining)
          end
          if sample.bytesize >= CONTENT_SAMPLE_BYTES
            truncated = true
            break
          end
        end
      end
    end

    marker = {
      "http_status" => status_code,
      "content_type" => content_type,
      "content_range" => content_range,
      "sample_bytes" => sample.bytesize,
      "sample_sha256" => Digest::SHA256.hexdigest(sample),
      "sample_truncated" => truncated,
    }.compact
    marker["status"] = sample.empty? ? "empty_response" : "captured"
    marker
  rescue StandardError => error
    {
      "status" => "unavailable",
      "error_class" => error.class.name,
    }
  end

  def comparison_for(source_id, state_signature, content_marker)
    baseline = @baseline_sources.fetch(source_id, nil)
    return { "change_signal" => "baseline_missing", "manual_review_required" => true } if baseline.nil? || baseline["state_signature"].to_s.empty?
    unless content_marker["status"] == "captured"
      return { "change_signal" => "content_marker_inconclusive", "manual_review_required" => true }
    end

    changed = baseline["state_signature"] != state_signature
    {
      "baseline_state_signature" => baseline["state_signature"],
      "change_detected" => changed,
      "change_signal" => changed ? "change_detected" : "unchanged",
      "manual_review_required" => changed,
    }
  end

  def offline_observation(source)
    source.merge(
      "observation_status" => "offline_not_checked",
      "automatic_approval" => false,
      "manual_review_required" => true,
      "change_signal" => "observation_not_run",
    )
  end

  def write_report
    target = File.absolute_path(@report_path, @repo_root)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, JSON.pretty_generate(@report) + "\n")
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    repo_root: File.expand_path("../..", __dir__),
    report_path: ".quality/compliance-horizon/source-observation.json",
    baseline_path: "docs/project/compliance/source-observation-baseline.yaml",
    offline: false,
  }
  OptionParser.new do |parser|
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--report PATH") { |value| options[:report_path] = value }
    parser.on("--baseline PATH") { |value| options[:baseline_path] = value }
    parser.on("--offline") { options[:offline] = true }
  end.parse!

  observer = ComplianceSourceObserver.new(**options)
  observer.run
  puts "Compliance source observation written: #{observer.report['sources'].length} official sources, #{observer.report['mode']} mode, manual review required"
end
