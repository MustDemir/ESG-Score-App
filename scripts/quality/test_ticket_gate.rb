#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "validate_tickets"

class TicketControlValidatorTest < Minitest::Test
  REPO_ROOT = File.expand_path("../..", __dir__)
  SOURCE_DIR = File.join(REPO_ROOT, "docs/project/tickets")

  def test_current_ticket_catalog_passes
    validator = TicketControlValidator.new(repo_root: REPO_ROOT)
    assert validator.run, validator.violations.join("\n")
  end

  def test_missing_required_section_fails
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") { |ticket| ticket.delete("definition_of_done") }
      assert_violation(dir, "missing field definition_of_done")
    end
  end

  def test_inconsistent_readiness_fails
    with_tickets do |dir|
      mutate(dir, "tkt-040-01-ticket-workflow-integrieren.yaml") { |ticket| ticket["definition_of_ready"]["status"] = "not_ready" }
      assert_violation(dir, "definition_of_ready.status must be ready")
    end
  end

  def test_unknown_gate_fails
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") { |ticket| ticket["gates"]["required"] << "G-NOT-REAL" }
      assert_violation(dir, "unknown gate G-NOT-REAL")
    end
  end

  def test_unknown_definition_of_done_task_type_fails
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") { |ticket| ticket["ticket_type"] = "not_a_task_type" }
      assert_violation(dir, "ticket_type must reference a Definition-of-Done task type")
    end
  end

  def test_satisfied_readiness_requires_existing_evidence
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
        ticket["definition_of_ready"]["criteria"][0]["evidence"] = ["docs/project/not-present.yaml"]
      end
      assert_violation(dir, "evidence path does not exist")
    end
  end

  def test_parent_todo_must_link_every_child_ticket
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") { |ticket| ticket["parent_todo"] = "TODO-038" }
      assert_violation(dir, "TODO-038: tickets must equal TKT-037-01")
    end
  end

  def test_unknown_dependency_fails
    with_tickets do |dir|
      mutate(dir, "tkt-037-02-migration-14-remote-anwenden.yaml") { |ticket| ticket["dependencies"] = ["TKT-999-99"] }
      assert_violation(dir, "unknown dependency TKT-999-99")
    end
  end

  def test_dependency_cycle_fails
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") { |ticket| ticket["dependencies"] = ["TKT-037-02"] }
      assert_violation(dir, "ticket dependency cycle")
    end
  end

  def test_done_without_completion_and_evidence_fails
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
        ticket["status"] = "done"
        ticket["evidence"] = []
      end
      assert_violation(dir, "done ticket requires completed DoD")
      assert_violation(dir, "done ticket requires evidence")
    end
  end

  def test_index_must_include_every_ticket_once
    with_tickets do |dir|
      mutate(dir, "ticket-index.yaml") { |index| index["execution_order"].delete("TKT-037-04") }
      assert_violation(dir, "execution_order missing TKT-037-04")
    end
  end

  def test_current_date_update_passes_but_future_update_fails
    with_tickets do |dir|
      filename = "tkt-040-01-ticket-workflow-integrieren.yaml"
      mutate(dir, filename) { |ticket| ticket["updated"] = Date.today }
      validator = TicketControlValidator.new(repo_root: REPO_ROOT, tickets_dir: dir)
      assert validator.run, validator.violations.join("\n")
      mutate(dir, filename) { |ticket| ticket["updated"] = Date.today + 1 }
      assert_violation(dir, "updated cannot be in the future")
    end
  end

  def test_not_applicable_requires_reason_owner_and_evidence
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
        criterion = ticket["definition_of_ready"]["criteria"][0]
        criterion["status"] = "not_applicable"
        criterion["evidence"] = []
      end
      assert_violation(dir, "not_applicable requires not_applicable_reason")
      assert_violation(dir, "not_applicable requires decision_owner")
      assert_violation(dir, "not_applicable requires evidence")
    end
  end

  def test_documented_not_applicable_is_structurally_valid
    with_tickets do |dir|
      mutate(dir, "tkt-040-01-ticket-workflow-integrieren.yaml") do |ticket|
        criterion = ticket["definition_of_ready"]["criteria"][0]
        criterion["status"] = "not_applicable"
        criterion["not_applicable_reason"] = "Synthetic exception for structural validation only."
        criterion["decision_owner"] = "Fixture reviewer"
        criterion["evidence"] = ["docs/project/decisions/0041-ticket-based-execution-control.yaml"]
      end
      validator = TicketControlValidator.new(repo_root: REPO_ROOT, tickets_dir: dir)
      assert validator.run, validator.violations.join("\n")
    end
  end

  def test_mandatory_human_criterion_cannot_be_waived_with_metadata
    [["acceptance_criteria", "AC-02"], ["definition_of_done", "DOD-02"]].each do |section, id|
      with_tickets do |dir|
        mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
          criteria = section == "acceptance_criteria" ? ticket[section] : ticket[section]["criteria"]
          criterion = criteria.find { |item| item["id"] == id }
          assert_equal false, criterion["not_applicable_allowed"], "#{id} must prohibit a waiver"
          criterion["status"] = "not_applicable"
          criterion["not_applicable_reason"] = "Attempted waiver"
          criterion["decision_owner"] = "Fixture reviewer"
          criterion["evidence"] = ["docs/project/decisions/0041-ticket-based-execution-control.yaml"]
        end
        assert_violation(dir, "not_applicable is forbidden for this criterion")
      end
    end
  end

  def test_unjustified_waivers_cannot_close_privacy_ticket
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
        ticket["status"] = "done"
        criteria = ticket["definition_of_ready"]["criteria"] + ticket["acceptance_criteria"] + ticket["definition_of_done"]["criteria"]
        criteria.each { |criterion| criterion["status"] = "not_applicable"; criterion["evidence"] = [] }
        ticket["definition_of_ready"]["status"] = "ready"
        ticket["definition_of_done"]["status"] = "done"
        ticket["evidence"] = ["proof-that-does-not-exist.txt"]
      end
      assert_violation(dir, "not_applicable requires not_applicable_reason")
      assert_violation(dir, "evidence path does not exist")
    end
  end

  def test_missing_top_level_evidence_file_fails
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
        ticket["evidence"] = ["proof-that-does-not-exist.txt"]
      end
      assert_violation(dir, "evidence path does not exist")
    end
  end

  def test_evidence_directory_and_empty_reference_fail
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
        ticket["evidence"] = ["docs/project", ""]
      end
      assert_violation(dir, "evidence must reference a file")
      assert_violation(dir, "evidence reference must be a nonempty string")
    end
  end

  def test_evidence_cannot_escape_repository_by_traversal_absolute_path_or_symlink
    Dir.mktmpdir("scanfair-evidence-boundary") do |tmp|
      root = File.join(tmp, "repo")
      FileUtils.mkdir_p(root)
      outside = File.join(tmp, "outside.txt")
      File.write(outside, "synthetic evidence")
      File.symlink(outside, File.join(root, "escape.txt"))
      ["../outside.txt", outside, "escape.txt"].each do |reference|
        validator = TicketControlValidator.new(repo_root: root)
        validator.send(:validate_evidence_references, [reference], "fixture")
        assert validator.violations.any? { |v| v.include?("must stay inside repository") }, reference
      end
    end
  end

  def test_done_ticket_must_also_be_ready
    with_tickets do |dir|
      mutate(dir, "tkt-037-01-privacy-pruefung-ip-pseudonyme.yaml") do |ticket|
        ticket["status"] = "done"
        ticket["definition_of_ready"]["status"] = "not_ready"
        ticket["definition_of_ready"]["criteria"][0]["status"] = "pending"
      end
      assert_violation(dir, "done ticket must be ready")
    end
  end

  def test_next_ticket_cannot_be_terminal
    with_tickets do |dir|
      mutate_next_ticket(dir) { |ticket| ticket["status"] = "dropped" }
      assert_violation(dir, "next_ticket must not be terminal")
    end
  end

  def test_next_ready_ticket_requires_completed_dependencies
    with_tickets do |dir|
      mutate_next_ticket(dir) { |ticket| ticket["dependencies"] = ["TKT-040-01"] }
      assert_violation(dir, "next_ticket dependency TKT-040-01 is not done")
    end
  end

  private

  def with_tickets
    Dir.mktmpdir("scanfair-ticket-test") do |tmp|
      target = File.join(tmp, "tickets")
      FileUtils.cp_r(SOURCE_DIR, target)
      yield target
    end
  end

  def mutate(dir, filename)
    path = File.join(dir, filename)
    document = YAML.safe_load(File.read(path), permitted_classes: [Date], aliases: true)
    yield document
    File.write(path, YAML.dump(document))
  end

  def mutate_next_ticket(dir, &block)
    index = YAML.safe_load(File.read(File.join(dir, "ticket-index.yaml")), permitted_classes: [Date], aliases: true)
    path = Dir.glob(File.join(dir, "#{index.fetch('next_ticket').downcase}-*.yaml")).fetch(0)
    mutate(dir, File.basename(path), &block)
  end

  def assert_violation(dir, text)
    validator = TicketControlValidator.new(repo_root: REPO_ROOT, tickets_dir: dir)
    refute validator.run
    assert validator.violations.any? { |violation| violation.include?(text) }, validator.violations.join("\n")
  end
end
