#!/usr/bin/env ruby
# frozen_string_literal: true

# Validates OpenCode manifests: agent/command/skill frontmatter and team.yaml.
# Stdlib only; no gems. Run with: ruby scripts/validate.rb

require "yaml"

ROOT = File.expand_path("..", __dir__)
# Skills that must not leak back into this self-contained repository.
FORBIDDEN_STAGE_SKILLS = %w[logo-design to-tickets tdd].freeze
EXTERNAL_SKILL_REFS = %w[logo-design to-tickets codebase-design code-review setup-matt-pocock-skills].freeze
errors = []

def parse_frontmatter(path)
  m = File.read(path).match(/\A---\r?\n(.*?)\r?\n---\r?\n/m)
  return nil unless m

  YAML.safe_load(m[1], permitted_classes: [], aliases: false) || {}
rescue Psych::SyntaxError => e
  raise "frontmatter YAML: #{e.message.lines.first.strip}"
end

def check(errors, path, ok, msg)
  errors << "#{path}: #{msg}" unless ok
end

files = Dir[File.join(ROOT, "{agents,commands}/*.md")].sort
skills = Dir[File.join(ROOT, "skills/*/SKILL.md")].sort
agent_names = Dir[File.join(ROOT, "agents/*.md")].map { |f| File.basename(f, ".md") }

# --- agents & commands ---
files.each do |path|
  rel = path.sub("#{ROOT}/", "")
  begin
    fm = parse_frontmatter(path)
  rescue StandardError => e
    errors << "#{rel}: #{e.message}"
    next
  end
  unless fm
    errors << "#{rel}: missing frontmatter"
    next
  end

  check(errors, rel, fm["name"].is_a?(String) && !fm["name"].empty?, "missing name")
  check(errors, rel, fm["description"].is_a?(String) && !fm["description"].empty?, "missing description")

  expected = File.basename(path, ".md")
  check(errors, rel, fm["name"] == expected, "name #{fm["name"].inspect} != filename #{expected.inspect}")

  if rel.start_with?("agents/")
    modes = %w[primary subagent all]
    check(errors, rel, modes.include?(fm["mode"]), "mode must be primary|subagent|all, got #{fm["mode"].inspect}")
  end

  if rel.start_with?("commands/") && fm["agent"]
    check(errors, rel, agent_names.include?(fm["agent"]), "agent #{fm["agent"].inspect} has no agents/#{fm["agent"]}.md")
  end

  # This repo is self-contained: agents and commands must not require global skills.
  source = File.read(path)
  EXTERNAL_SKILL_REFS.each do |name|
    check(errors, rel, source !~ /\b#{Regexp.escape(name)}\b/, "references external skill #{name.inspect}")
  end
end

# --- one writer per stage artifact ---
# Write paths live in prose. Flag two roles being told to write the same .team
# artifact; parallel specialists would otherwise overwrite each other.
writes = Hash.new { |h, k| h[k] = [] }
Dir[File.join(ROOT, "agents/*.md")].sort.each do |path|
  role = File.basename(path, ".md")
  File.readlines(path).each do |line|
    next if line.match?(/do not write/i)
    next unless line.match?(/\bwrite\b/i)

    line.scan(/\.team\/\d{2}-[a-z-]+\.md/i) { |artifact| writes[artifact] << role }
  end
end
writes.each do |artifact, roles|
  next if roles.uniq.size < 2

  errors << "agents/*.md: #{roles.uniq.join(", ")} all write #{artifact}; use one writer per artifact"
end

# --- skills ---
skills.each do |path|
  rel = path.sub("#{ROOT}/", "")
  begin
    fm = parse_frontmatter(path)
  rescue StandardError => e
    errors << "#{rel}: #{e.message}"
    next
  end
  unless fm
    errors << "#{rel}: missing frontmatter"
    next
  end

  check(errors, rel, fm["name"].is_a?(String) && !fm["name"].empty?, "missing name")
  check(errors, rel, fm["description"].is_a?(String) && !fm["description"].empty?, "missing description")

  expected = File.basename(File.dirname(path))
  check(errors, rel, fm["name"] == expected, "name #{fm["name"].inspect} != dir #{expected.inspect}")
end

# --- team.yaml ---
team = {}
begin
  team = YAML.safe_load(File.read(File.join(ROOT, "team.yaml")), permitted_classes: [], aliases: false) || {}
rescue Psych::SyntaxError => e
  errors << "team.yaml: #{e.message.lines.first.strip}"
end

artifact_dir = team["artifact_dir"]
check(errors, "team.yaml", artifact_dir.is_a?(String) && !artifact_dir.empty?, "missing artifact_dir")

stages = team["stages"]
if stages.is_a?(Array)
  ids = []
  outputs = []
  stages.each_with_index do |s, i|
    id = s["id"] || "stages[#{i}]"
    check(errors, "team.yaml", s["id"].is_a?(String) && !s["id"].empty?, "#{id}: missing id")
    check(errors, "team.yaml", s["title"].is_a?(String) && !s["title"].empty?, "#{id}: missing title")
    check(errors, "team.yaml", s["agent"].is_a?(String), "#{id}: missing agent")
    check(errors, "team.yaml", s["skill"].is_a?(String) && !s["skill"].empty?, "#{id}: missing skill")
    check(errors, "team.yaml", [true, false].include?(s["gate"]), "#{id}: gate must be true|false, got #{s["gate"].inspect}")
    check(errors, "team.yaml", s["brief"].is_a?(String) && !s["brief"].empty?, "#{id}: missing brief")
    check(errors, "team.yaml", s["output"].is_a?(String) && !s["output"].empty?, "#{id}: missing output")

    if s["id"]
      check(errors, "team.yaml", !ids.include?(s["id"]), "#{id}: duplicate stage id")
      ids << s["id"]
    end
    if s["output"]
      check(errors, "team.yaml", !outputs.include?(s["output"]), "#{id}: duplicate output #{s["output"].inspect}")
      outputs << s["output"]
      if artifact_dir.is_a?(String) && !artifact_dir.empty?
        check(errors, "team.yaml", s["output"].start_with?("#{artifact_dir}/"),
              "#{id}: output #{s["output"].inspect} must be under #{artifact_dir}/")
      end
    end

    if s["agent"]
      check(errors, "team.yaml", agent_names.include?(s["agent"]), "#{id}: agent #{s["agent"].inspect} has no agents/#{s["agent"]}.md")
    end
    if s["skill"].is_a?(String) && !s["skill"].empty?
      check(errors, "team.yaml", !FORBIDDEN_STAGE_SKILLS.include?(s["skill"]),
            "#{id}: external skill #{s["skill"].inspect} is not allowed in this repository")
      check(errors, "team.yaml", File.file?(File.join(ROOT, "skills", s["skill"], "SKILL.md")),
            "#{id}: skill #{s["skill"].inspect} has no skills/#{s["skill"]}/SKILL.md")
    end
    Array(s["support"]).each do |a|
      check(errors, "team.yaml", agent_names.include?(a), "#{id}: support #{a.inspect} has no agents/#{a}.md")
    end
  end
else
  errors << "team.yaml: stages must be an array"
end

profiles = team["profiles"]
if profiles.is_a?(Hash) && stages.is_a?(Array)
  ids = stages.map { |s| s["id"] }
  profiles.each do |name, list|
    next unless list.is_a?(Array)

    list.each do |stage_id|
      check(errors, "team.yaml", ids.include?(stage_id), "profile #{name.inspect}: unknown stage #{stage_id.inspect}")
    end
  end
end

# --- report ---
count = files.size + skills.size + 1
if errors.empty?
  puts "validate: #{count} files OK"
  exit 0
else
  errors.each { |e| puts "  ✗ #{e}" }
  puts "validate: #{errors.size} error(s) in #{count} files"
  exit 1
end
