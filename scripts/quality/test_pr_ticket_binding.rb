#!/usr/bin/env ruby

require "fileutils"
require "json"
require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "validate_pr_ticket_binding"

class PullRequestTicketBindingValidatorTest < Minitest::Test
  REPO_ROOT = File.expand_path("../..", __dir__)
  SOURCE_DIR = File.join(REPO_ROOT, "docs/project/tickets")

  def test_ci_rechecks_binding_after_body_edits_and_for_all_changed_paths
    workflow = YAML.safe_load(
      File.read(File.join(REPO_ROOT, ".github/workflows/quality-gates.yml")),
      aliases: true,
    )
    triggers = workflow["on"] || workflow[true]
    pull_request = triggers.fetch("pull_request")
    %w[opened synchronize reopened edited ready_for_review].each do |event|
      assert_includes pull_request.fetch("types"), event
    end
    refute pull_request.key?("paths"), "ticket binding must cover every PR"
    refute pull_request.key?("paths-ignore"), "ticket binding must cover every PR"
  end

  def test_review_ticket_with_matching_parent_passes
    with_fixture("Ticket: TKT-040-01\nParent: TODO-040") do |event, tickets|
      validator = build_validator(event, tickets)
      assert validator.run, validator.violations.join("\n")
    end
  end

  def test_missing_ticket_fails
    with_fixture("Parent: TODO-040") { |event, tickets| assert_violation(event, tickets, "exactly one ticket ID") }
  end

  def test_multiple_ticket_ids_fail
    with_fixture("TKT-040-01 TKT-037-01 TODO-040") { |event, tickets| assert_violation(event, tickets, "exactly one ticket ID") }
  end

  def test_wrong_parent_fails
    with_fixture("TKT-040-01 TODO-037") { |event, tickets| assert_violation(event, tickets, "does not match TODO-040") }
  end

  def test_unknown_ticket_fails
    with_fixture("TKT-999-99 TODO-040") { |event, tickets| assert_violation(event, tickets, "expected exactly one repository ticket, found 0") }
  end

  def test_planned_ticket_is_not_reviewable
    with_fixture("TKT-037-01 TODO-037") { |event, tickets| assert_violation(event, tickets, "status \"planned\" is not reviewable") }
  end

  def test_done_ticket_is_not_reviewable
    with_fixture("TKT-040-01 TODO-040") do |event, tickets|
      mutate(File.join(tickets, "tkt-040-01-ticket-workflow-integrieren.yaml")) { |ticket| ticket["status"] = "done" }
      assert_violation(event, tickets, "status \"done\" is not reviewable")
    end
  end

  def test_active_ticket_must_match_review_ticket
    with_fixture("TKT-040-01 TODO-040") do |event, tickets|
      mutate(File.join(tickets, "ticket-index.yaml")) { |index| index["active_ticket"] = nil }
      assert_violation(event, tickets, "must match ticket-index.active_ticket")
    end
  end

  def test_non_pull_request_event_fails
    with_fixture(nil, event: { "ref" => "refs/heads/main" }) do |event, tickets|
      assert_violation(event, tickets, "does not contain a pull_request")
    end
  end

  private

  def with_fixture(body, event: nil)
    Dir.mktmpdir("scanfair-pr-ticket-test") do |tmp|
      tickets = File.join(tmp, "tickets")
      FileUtils.cp_r(SOURCE_DIR, tickets)
      # Fixture lifecycle is independent of the live catalog's active work.
      mutate(File.join(tickets, "tkt-040-01-ticket-workflow-integrieren.yaml")) { |ticket| ticket["status"] = "review" }
      mutate(File.join(tickets, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml")) { |ticket| ticket["status"] = "planned" }
      mutate(File.join(tickets, "ticket-index.yaml")) { |index| index["active_ticket"] = "TKT-040-01" }
      event_path = File.join(tmp, "event.json")
      payload = event || { "pull_request" => { "body" => body } }
      File.write(event_path, JSON.generate(payload))
      yield event_path, tickets
    end
  end

  def build_validator(event, tickets)
    PullRequestTicketBindingValidator.new(repo_root: REPO_ROOT, event_path: event, tickets_dir: tickets)
  end

  def assert_violation(event, tickets, text)
    validator = build_validator(event, tickets)
    refute validator.run
    assert validator.violations.any? { |violation| violation.include?(text) }, validator.violations.join("\n")
  end

  def mutate(path)
    document = YAML.safe_load(File.read(path), permitted_classes: [Date], aliases: true)
    yield document
    File.write(path, YAML.dump(document))
  end
end
