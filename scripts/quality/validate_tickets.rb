#!/usr/bin/env ruby

require "date"
require "yaml"
require "uri"

class TicketControlValidator
  attr_reader :violations, :tickets

  ACTIVE_STATUSES = %w[in_progress draft review].freeze
  TERMINAL_STATUSES = %w[done dropped].freeze

  def initialize(repo_root:, tickets_dir: nil, today: Date.today)
    @repo_root = repo_root
    @tickets_dir = tickets_dir || File.join(repo_root, "docs/project/tickets")
    @schema_path = File.join(@tickets_dir, "ticket-schema.yaml")
    @index_path = File.join(@tickets_dir, "ticket-index.yaml")
    @today = today
    @violations = []
    @tickets = []
  end

  def run
    load_contracts
    return false unless @schema && @index && @backlog && @definition_of_done

    validate_schema
    load_tickets
    validate_tickets
    validate_dependencies
    validate_index
    validate_backlog_links
    violations.empty?
  rescue Psych::SyntaxError => error
    violations << "YAML syntax error: #{error.message}"
    false
  rescue KeyError => error
    violations << "ticket control missing key: #{error.message}"
    false
  end

  private

  def load_yaml(path, label)
    unless File.file?(path)
      violations << "#{label}: file is missing"
      return nil
    end
    YAML.safe_load(File.read(path), permitted_classes: [Date], aliases: true)
  end

  def load_contracts
    @schema = load_yaml(@schema_path, relative(@schema_path))
    @index = load_yaml(@index_path, relative(@index_path))
    @backlog = load_yaml(File.join(@repo_root, "docs/project/backlog.yaml"), "docs/project/backlog.yaml")
    @definition_of_done = load_yaml(File.join(@repo_root, "docs/project/definition-of-done.yaml"), "docs/project/definition-of-done.yaml")
    risks = load_yaml(File.join(@repo_root, "docs/project/risks.yaml"), "docs/project/risks.yaml")
    @risk_ids = Array(risks && risks["risks"]).map { |item| item["id"] }
    @todo_by_id = Array(@backlog && @backlog["todos"]).to_h { |item| [item["id"], item] }
    @dod_task_type_ids = Array(@definition_of_done && @definition_of_done["task_types"]).map { |item| item["id"] }
    @decision_ids = Dir.glob(File.join(@repo_root, "docs/project/decisions/[0-9][0-9][0-9][0-9]-*.yaml")).map { |path| File.basename(path)[0, 4] }
    @requirement_ids = Dir.glob(File.join(@repo_root, "docs/project/requirements/R-*.yaml")).map { |path| File.basename(path, ".yaml") }
  end

  def validate_schema
    label = relative(@schema_path)
    unless @schema["schema_version"] == "scanfair-ticket-schema-v1" &&
           @schema["ticket_schema_version"] == "scanfair-ticket-v1"
      violations << "#{label}: unsupported schema version"
    end
    %w[required_fields allowed_values minimum_items required_gates_by_ticket_type state_rules].each do |field|
      violations << "#{label}: #{field} must not be empty" if empty?(@schema[field])
    end
  end

  def load_tickets
    paths = Dir.glob(File.join(@tickets_dir, "tkt-*.yaml")).sort
    violations << "docs/project/tickets: at least one ticket is required" if paths.empty?
    @tickets = paths.each_with_object([]) do |path, loaded|
      ticket = load_yaml(path, relative(path))
      loaded << ticket.merge("__path" => path) if ticket
    end
  end

  def validate_tickets
    ids = tickets.map { |ticket| ticket["id"] }
    counts(ids).each { |id, count| violations << "duplicate ticket id #{id}" if id && count > 1 }
    tickets.each { |ticket| validate_ticket(ticket, ids) }
  end

  def validate_ticket(ticket, all_ids)
    label = relative(ticket["__path"])
    Array(@schema["required_fields"]).each do |field|
      violations << "#{label}: missing field #{field}" unless ticket.key?(field)
    end
    id = ticket["id"]
    unless id.to_s.match?(/\ATKT-\d{3}-\d{2}\z/)
      violations << "#{label}: invalid ticket id #{id.inspect}"
    end
    unless File.basename(label).start_with?(id.to_s.downcase + "-")
      violations << "#{label}: filename must start with #{id.to_s.downcase}-"
    end
    %w[title summary owner decision_owner activation_boundary].each do |field|
      violations << "#{id || label}: #{field} must not be empty" if empty?(ticket[field])
    end

    allowed = @schema.fetch("allowed_values")
    unless @dod_task_type_ids.include?(ticket["ticket_type"])
      violations << "#{label}: ticket_type must reference a Definition-of-Done task type"
    end
    validate_enum(ticket, "priority", allowed["priorities"], label)
    validate_enum(ticket, "status", allowed["statuses"], label)
    validate_dates(ticket, label)
    validate_scope(ticket, label)
    validate_links(ticket, label)
    validate_task_types(ticket, label)
    validate_checklists(ticket, label)
    validate_gates(ticket, label)
    validate_rollback(ticket, label)
    validate_evidence_references(ticket["evidence"], "#{label}: evidence")

    Array(ticket["dependencies"]).each do |dependency|
      violations << "#{id}: unknown dependency #{dependency}" unless all_ids.include?(dependency)
      violations << "#{id}: ticket cannot depend on itself" if dependency == id
    end
  end

  def validate_enum(record, field, allowed, label)
    return if Array(allowed).include?(record[field])
    violations << "#{label}: invalid #{field} #{record[field].inspect}"
  end

  def validate_dates(ticket, label)
    created = parse_date(ticket["created"], "#{label}: created")
    updated = parse_date(ticket["updated"], "#{label}: updated")
    violations << "#{label}: updated cannot precede created" if created && updated && updated < created
    violations << "#{label}: updated cannot be in the future" if updated && updated > @today
  end

  def parse_date(value, label)
    Date.iso8601(value.to_s)
  rescue Date::Error
    violations << "#{label} must be an ISO date"
    nil
  end

  def validate_scope(ticket, label)
    scope = ticket["scope"]
    unless scope.is_a?(Hash)
      violations << "#{label}: scope must be a mapping"
      return
    end
    minimums = @schema.fetch("minimum_items")
    violations << "#{label}: scope.in is incomplete" if Array(scope["in"]).length < minimums["scope_in"].to_i
    violations << "#{label}: scope.out is incomplete" if Array(scope["out"]).length < minimums["scope_out"].to_i
  end

  def validate_links(ticket, label)
    links = ticket["links"]
    unless links.is_a?(Hash)
      violations << "#{label}: links must be a mapping"
      return
    end
    %w[risks decisions requirements].each do |field|
      violations << "#{label}: links.#{field} must be a list" unless links[field].is_a?(Array)
    end
    Array(links["risks"]).each { |id| violations << "#{label}: unknown risk #{id}" unless @risk_ids.include?(id) }
    Array(links["decisions"]).each { |id| violations << "#{label}: unknown decision #{id}" unless @decision_ids.include?(id.to_s) }
    Array(links["requirements"]).each { |id| violations << "#{label}: unknown requirement #{id}" unless @requirement_ids.include?(id) }
    violations << "#{label}: unknown parent TODO #{ticket['parent_todo']}" unless @todo_by_id.key?(ticket["parent_todo"])
  end

  def validate_task_types(ticket, label)
    task_types = Array(ticket["dod_task_types"])
    violations << "#{label}: dod_task_types must not be empty" if task_types.empty?
    task_types.each do |task_type|
      violations << "#{label}: unknown DoD task type #{task_type}" unless @dod_task_type_ids.include?(task_type)
    end
  end

  def validate_checklists(ticket, label)
    minimums = @schema.fetch("minimum_items")
    criterion_statuses = @schema.dig("allowed_values", "criterion_statuses")
    dor = validate_checklist(ticket["definition_of_ready"], "definition_of_ready", label, minimums["definition_of_ready"], criterion_statuses)
    acceptance = validate_items(ticket["acceptance_criteria"], "acceptance_criteria", label, minimums["acceptance_criteria"], criterion_statuses, acceptance: true)
    dod = validate_checklist(ticket["definition_of_done"], "definition_of_done", label, minimums["definition_of_done"], criterion_statuses)

    if dor
      expected = dor.any? { |item| item["status"] == "pending" } ? "not_ready" : "ready"
      actual = ticket.dig("definition_of_ready", "status")
      violations << "#{label}: definition_of_ready.status must be #{expected}" unless actual == expected
      validate_enum(ticket["definition_of_ready"], "status", @schema.dig("allowed_values", "readiness_statuses"), "#{label}: definition_of_ready")
    end
    if dod
      expected = dod.any? { |item| item["status"] == "pending" } ? "not_done" : "done"
      actual = ticket.dig("definition_of_done", "status")
      violations << "#{label}: definition_of_done.status must be #{expected}" unless actual == expected
      validate_enum(ticket["definition_of_done"], "status", @schema.dig("allowed_values", "completion_statuses"), "#{label}: definition_of_done")
    end

    if (ACTIVE_STATUSES + ["done"]).include?(ticket["status"]) && ticket.dig("definition_of_ready", "status") != "ready"
      violations << "#{label}: #{ticket['status']} ticket must be ready"
    end
    return unless ticket["status"] == "done"

    violations << "#{label}: done ticket has pending acceptance criteria" if acceptance&.any? { |item| item["status"] == "pending" }
    violations << "#{label}: done ticket requires completed DoD" unless ticket.dig("definition_of_done", "status") == "done"
    violations << "#{label}: done ticket requires evidence" if Array(ticket["evidence"]).empty?
  end

  def validate_checklist(section, name, label, minimum, statuses)
    unless section.is_a?(Hash)
      violations << "#{label}: #{name} must be a mapping"
      return nil
    end
    validate_items(section["criteria"], "#{name}.criteria", label, minimum, statuses)
  end

  def validate_items(items, name, label, minimum, statuses, acceptance: false)
    unless items.is_a?(Array)
      violations << "#{label}: #{name} must be a list"
      return nil
    end
    violations << "#{label}: #{name} needs at least #{minimum} items" if items.length < minimum.to_i
    ids = items.map { |item| item["id"] }
    counts(ids).each { |id, count| violations << "#{label}: duplicate #{name} id #{id}" if id && count > 1 }
    items.each_with_index do |item, index|
      item_label = "#{label}: #{name}[#{index}]"
      %w[id criterion status].each { |field| violations << "#{item_label}: #{field} must not be empty" if empty?(item[field]) }
      violations << "#{item_label}: invalid status #{item['status'].inspect}" unless Array(statuses).include?(item["status"])
      if item.key?("not_applicable_allowed") && ![true, false].include?(item["not_applicable_allowed"])
        violations << "#{item_label}: not_applicable_allowed must be boolean"
      end
      if item["status"] == "satisfied" && Array(item["evidence"]).empty?
        violations << "#{item_label}: satisfied criterion requires evidence"
      end
      if item["status"] == "not_applicable"
        violations << "#{item_label}: not_applicable is forbidden for this criterion" if item["not_applicable_allowed"] == false
        # This records an accountable exception; it does not verify a person's
        # authority or replace the separate human approval controls.
        %w[not_applicable_reason decision_owner].each do |field|
          unless item[field].is_a?(String) && !empty?(item[field])
            violations << "#{item_label}: not_applicable requires #{field}"
          end
        end
        violations << "#{item_label}: not_applicable requires evidence" if Array(item["evidence"]).empty?
      end
      if %w[satisfied not_applicable].include?(item["status"])
        validate_evidence_references(item["evidence"], item_label)
      end
      if acceptance
        violations << "#{item_label}: verification must not be empty" if Array(item["verification"]).empty?
        violations << "#{item_label}: evidence_required must not be empty" if Array(item["evidence_required"]).empty?
      end
    end
    items
  end

  def validate_gates(ticket, label)
    gates = ticket["gates"]
    unless gates.is_a?(Hash)
      violations << "#{label}: gates must be a mapping"
      return
    end
    required = Array(gates["required"])
    commands = Array(gates["commands"])
    minimum = @schema.dig("minimum_items", "required_gates").to_i
    violations << "#{label}: gates.required needs at least #{minimum} entries" if required.length < minimum
    violations << "#{label}: gates.commands must not be empty" if commands.empty?
    allowed = Array(@schema.dig("allowed_values", "gates"))
    required.each { |gate| violations << "#{label}: unknown gate #{gate}" unless allowed.include?(gate) }
    expected = Array(@schema.dig("required_gates_by_ticket_type", ticket["ticket_type"]))
    missing = expected - required
    violations << "#{label}: missing required gates #{missing.join(', ')}" unless missing.empty?
  end

  def validate_rollback(ticket, label)
    rollback = ticket["rollback"]
    unless rollback.is_a?(Hash) && !empty?(rollback["strategy"]) && !empty?(rollback["verification"])
      violations << "#{label}: rollback requires strategy and verification"
    end
  end

  def validate_dependencies
    by_id = tickets.to_h { |ticket| [ticket["id"], ticket] }
    visiting = {}
    visited = {}
    visit = lambda do |id, path|
      return if visited[id]
      if visiting[id]
        violations << "ticket dependency cycle #{(path + [id]).join(' -> ')}"
        return
      end
      visiting[id] = true
      ticket = by_id[id]
      Array(ticket && ticket["dependencies"]).each { |dependency| visit.call(dependency, path + [id]) if by_id.key?(dependency) }
      visiting.delete(id)
      visited[id] = true
    end
    by_id.each_key { |id| visit.call(id, []) }

    tickets.each do |ticket|
      next unless (ACTIVE_STATUSES + ["done"]).include?(ticket["status"])
      Array(ticket["dependencies"]).each do |dependency|
        if by_id[dependency] && by_id[dependency]["status"] != "done"
          violations << "#{ticket['id']}: dependency #{dependency} is not done"
        end
      end
    end
  end

  def validate_index
    label = relative(@index_path)
    %w[schema_version last_updated owner policy active_ticket next_ticket execution_order].each do |field|
      violations << "#{label}: missing field #{field}" unless @index.key?(field)
    end
    expected_policy = {
      "backlog_is_portfolio_ssot" => true,
      "ticket_required_before_state_change" => true,
      "maximum_active" => 1,
      "ready_required_before_in_progress" => true,
      "done_requires_acceptance_dod_evidence_and_gates" => true,
    }
    expected_policy.each do |field, value|
      violations << "#{label}: policy.#{field} must be #{value.inspect}" unless @index.dig("policy", field) == value
    end
    ids = tickets.map { |ticket| ticket["id"] }
    order = Array(@index["execution_order"])
    (ids - order).each { |id| violations << "#{label}: execution_order missing #{id}" }
    (order - ids).each { |id| violations << "#{label}: execution_order references unknown #{id}" }
    counts(order).each { |id, count| violations << "#{label}: execution_order repeats #{id}" if count > 1 }
    positions = order.each_with_index.to_h
    tickets.each do |ticket|
      Array(ticket["dependencies"]).each do |dependency|
        next unless positions[dependency] && positions[ticket["id"]]
        violations << "#{label}: #{dependency} must precede #{ticket['id']}" if positions[dependency] >= positions[ticket["id"]]
      end
    end

    active = tickets.select { |ticket| ACTIVE_STATUSES.include?(ticket["status"]) }
    maximum = @index.dig("policy", "maximum_active").to_i
    violations << "#{label}: more than #{maximum} ticket is active" if active.length > maximum
    expected_active = active.one? ? active.first["id"] : nil
    violations << "#{label}: active_ticket must match in_progress ticket" unless @index["active_ticket"] == expected_active

    next_ticket = tickets.find { |ticket| ticket["id"] == @index["next_ticket"] }
    violations << "#{label}: next_ticket is unknown" unless next_ticket
    if next_ticket && next_ticket.dig("definition_of_ready", "status") != "ready"
      violations << "#{label}: next_ticket must be ready"
    end
    if next_ticket
      violations << "#{label}: next_ticket must not be terminal" if TERMINAL_STATUSES.include?(next_ticket["status"])
      if next_ticket.dig("definition_of_ready", "status") == "ready"
        by_id = tickets.to_h { |ticket| [ticket["id"], ticket] }
        Array(next_ticket["dependencies"]).each do |dependency|
          unless by_id[dependency] && by_id[dependency]["status"] == "done"
            violations << "#{label}: next_ticket dependency #{dependency} is not done"
          end
        end
      end
    end
  end

  def validate_backlog_links
    tickets.group_by { |ticket| ticket["parent_todo"] }.each do |todo_id, child_tickets|
      todo = @todo_by_id[todo_id]
      next unless todo
      expected = child_tickets.map { |ticket| ticket["id"] }.sort
      actual = Array(todo["tickets"]).sort
      violations << "#{todo_id}: tickets must equal #{expected.join(', ')}" unless actual == expected
    end
  end

  def empty?(value)
    value.nil? || (value.respond_to?(:empty?) && value.empty?) || (value.is_a?(String) && value.strip.empty?)
  end

  def validate_evidence_references(references, label)
    unless references.is_a?(Array)
      violations << "#{label}: evidence must be a list"
      return
    end
    root = File.realpath(@repo_root)
    references.each do |reference|
      unless reference.is_a?(String) && !empty?(reference)
        violations << "#{label}: evidence reference must be a nonempty string"
        next
      end
      if reference.start_with?("https://")
        begin
          uri = URI.parse(reference)
          violations << "#{label}: invalid HTTPS evidence reference" if uri.host.to_s.empty?
        rescue URI::InvalidURIError
          violations << "#{label}: invalid HTTPS evidence reference"
        end
        next # Remote existence and human approval remain separate checks.
      end
      path = File.expand_path(reference, root)
      unless path.start_with?(root + File::SEPARATOR)
        violations << "#{label}: evidence path must stay inside repository: #{reference}"
        next
      end
      unless File.exist?(path)
        violations << "#{label}: evidence path does not exist: #{reference}"
        next
      end
      unless File.realpath(path).start_with?(root + File::SEPARATOR)
        violations << "#{label}: evidence path must stay inside repository: #{reference}"
        next
      end
      violations << "#{label}: evidence must reference a file: #{reference}" unless File.file?(path)
    end
  end

  def counts(values)
    values.each_with_object(Hash.new(0)) { |value, result| result[value] += 1 }
  end

  def relative(path)
    path.delete_prefix(@repo_root + "/")
  end
end

if $PROGRAM_NAME == __FILE__
  repo_root = File.expand_path("../..", __dir__)
  validator = TicketControlValidator.new(repo_root: repo_root)
  if validator.run
    puts "Ticket control PASS: #{validator.tickets.length} tickets are schema-valid and workflow-consistent"
    exit 0
  end
  warn "Ticket control validation failed:"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
