#!/usr/bin/env ruby
#
# @package enve-omics
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
# @update  Dec-08-2015
#

$:.push File.expand_path("lib", File.dirname(__FILE__))
require "enve-collection"
manif = ARGV.shift

abort "Usage:
#{$0} manifest.json" if manif.nil?
$stderr.puts "Loading <#{manif}>"
c = EnveCollection.new manif
t_names = c.tasks.map{ |t| t.task }

# Categories v. declarations
categorized = c.hash[:categories].values.map{ |sc| sc.values }.flatten.uniq
orphan = categorized - t_names
if orphan.any?
   $stderr.puts "> Uncategorized scripts (#{orphan.count}):"
   orphan.each{ |o| $stderr.puts "  o #{o}" }
end
undec = t_names - categorized
if undec.any?
   $stderr.puts "> Scripts categorized but undeclared (#{undec.count}):"
   undec.each{ |o| $stderr.puts "  o #{o}" }
end

# Evaluate individual scripts
known_t_fields = [:task, :description, :help_arg, :options, :requires]
known_o_fields = [:name, :description, :note, :opt, :arg, :mandatory, :values,
   :hidden, :as_is, :default, :multiple_sep]
empty_tasks = []
c.tasks.each do |task|
   if task.description.empty? and task.options.empty? and task.help_arg.nil?
      empty_tasks << task.task
      next
   end
   issues = []
   extra_f = task.hash.keys - known_t_fields
   issues << "Unused fields: #{extra_f.join(", ")}." if extra_f.any?
   issues << "Empty description." if task.description.empty?
   issues << "Empty options." if task.options.empty?
   issues << "No help command." if task.hash[:help_arg].nil?
   bad_req = (task.requires.map do |r|
      (r.hash[:description].nil? or r.hash[:description].empty?) ?
      "Requirement wihtout description: #{r.test}." :
      (r.test.nil? or r.test.empty?) ?
      "Requirement without test: #{r.description}" : nil
   end.compact)
   issues += bad_req if bad_req.any?
   task.options.each do |opt|
      extra_f = opt.hash.keys - known_o_fields
      issues << "Unused fields in option: #{opt.name}: " +
	 extra_f.join(", ") + "." if extra_f.any?
      issues << "Select option without values: #{opt.name}." if
	 opt.arg==:select and
	 (opt.hash[:values].nil? or opt.hash[:values].empty?)
      issues << "Check option with unused default: #{opt.name}." if
	 opt.arg==:nil and not opt.default.nil?
      issues << "Hidden option with unused default: #{opt.name}." if
	 opt.hidden? and not opt.default.nil?
      issues << "Check option cannot be mandatory: #{opt.name}." if
	 opt.arg==:nil and opt.mandatory?
      issues << "Check option cannot have empty opt: #{opt.name}." if
	 opt.arg==:nil and (opt.opt.nil? or opt.opt.empty?)
      issues << "Option description doesn't end in period: #{opt.name}: " +
	 opt.description if not opt.hidden? and not opt.description.empty? and
	 opt.description[-1] != "."
   end

   if issues.any?
      $stderr.puts "> #{task.task} issues (#{issues.count}):"
      issues.each{ |o| $stderr.puts "  o #{o}" }
   end
end

if empty_tasks.any?
   $stderr.puts "> Empty tasks (#{empty_tasks.count}):"
   empty_tasks.each{ |o| $stderr.puts "  o #{o}" }
end
