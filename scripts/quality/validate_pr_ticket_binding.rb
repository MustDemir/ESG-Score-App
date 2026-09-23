#!/usr/bin/env ruby

require "json"
require "optparse"
require "date"
require "yaml"

class PullRequestTicketBindingValidator
  attr_reader :violations

  REVIEWABLE_STATUSES = %w[in_progress draft review done].freeze

  def initialize(repo_root:, event_path:, tickets_dir: nil)
    @repo_root = repo_root
    @event_path = event_path
    @tickets_dir = tickets_dir || File.join(repo_root, "docs/project/tickets")
    @violations = []
  end

  def run
    event = JSON.parse(File.read(@event_path))
    pull_request = event["pull_request"]
    unless pull_request.is_a?(Hash)
      violations << "event does not contain a pull_request"
      return false
    end
    body = pull_request["body"].to_s

    ticket_ids = body.scan(/\bTKT-\d{3}-\d{2}\b/).uniq
    todo_ids = body.scan(/\bTODO-\d{3}\b/).uniq
    violations << "pull request body must reference exactly one ticket ID" unless ticket_ids.length == 1
    violations << "pull request body must reference exactly one parent TODO" unless todo_ids.length == 1
    return false unless ticket_ids.length == 1 && todo_ids.length == 1

    ticket = load_ticket(ticket_ids.first)
    return false unless ticket

    unless REVIEWABLE_STATUSES.include?(ticket["status"])
      violations << "#{ticket_ids.first}: status #{ticket['status'].inspect} is not reviewable"
    end
    unless ticket["parent_todo"] == todo_ids.first
      violations << "#{ticket_ids.first}: PR parent #{todo_ids.first} does not match #{ticket['parent_todo']}"
    end

    index = load_yaml(File.join(@tickets_dir, "ticket-index.yaml"), "ticket index")
    if index
      unless Array(index["execution_order"]).include?(ticket_ids.first)
        violations << "#{ticket_ids.first}: ticket is missing from execution_order"
      end
      if %w[in_progress draft review].include?(ticket["status"]) && index["active_ticket"] != ticket_ids.first
        violations << "#{ticket_ids.first}: active PR ticket must match ticket-index.active_ticket"
      end
    end

    violations.empty?
  rescue Errno::ENOENT => error
    violations << "PR ticket binding file is missing: #{error.message}"
    false
  rescue JSON::ParserError => error
    violations << "invalid GitHub event JSON: #{error.message}"
    false
  rescue Psych::SyntaxError => error
    violations << "invalid ticket YAML: #{error.message}"
    false
  end

  private

  def load_ticket(id)
    matches = Dir.glob(File.join(@tickets_dir, "#{id.downcase}-*.yaml"))
    if matches.length != 1
      violations << "#{id}: expected exactly one repository ticket, found #{matches.length}"
      return nil
    end
    load_yaml(matches.first, id)
  end

  def load_yaml(path, label)
    YAML.safe_load(File.read(path), permitted_classes: [Date], aliases: true)
  rescue Errno::ENOENT
    violations << "#{label}: file is missing"
    nil
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  OptionParser.new do |parser|
    parser.on("--event PATH", "GitHub pull_request event JSON") { |path| options[:event_path] = path }
  end.parse!

  if options[:event_path].to_s.empty?
    warn "Usage: ruby scripts/quality/validate_pr_ticket_binding.rb --event PATH"
    exit 2
  end

  repo_root = File.expand_path("../..", __dir__)
  validator = PullRequestTicketBindingValidator.new(repo_root: repo_root, event_path: options[:event_path])
  if validator.run
    puts "PR ticket binding PASS"
    exit 0
  end
  warn "PR ticket binding failed:"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
