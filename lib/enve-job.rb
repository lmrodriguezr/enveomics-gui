require "open3"
require "tempfile"
require "shellwords"

class EnveJob
   # Class-level
   def self.scripts
      File.expand_path("enveomics-master/Scripts", EnveCollection.home)
   end
   # Instance-level
   attr_accessor :task, :values, :start_time, :end_time, :logfile, :pipe
   def initialize(task, values)
      @task = task
      @values = values
      run!
   end
   def run!
      @logfile = Tempfile.new("enveomics")
      logfile.close
      ObjectSpace.define_finalizer(self, proc{ logfile.unlink })
      @pipe = build_pipe
      pipe.add_log(log_path)
      @start_time = Time.now
      # This seems like the best solution, but it's not supported by
      # JRuby 1.7.x, so it breaks packaging [See #15]:
      # @wait_thr = Open3.pipeline_start(*pipe.to_open3_pipeline).last
      @script = Tempfile.new("enveomics")
      @script.puts cmd
      @script.close
      script_call = "#{EnveTask.BASH.shellescape} #{@script.path.shellescape}"
      @wait_thr = Open3.pipeline_start(script_call).last
      # And some other options to explore in the future:
      # @wait_thr = spawn(*pipe.to_spawn)
      # @wait_thr = Thread.new { IO.popen(cmd){} }
   end
   def status
      @wait_thr.status
   end
   def alive?
      o = @wait_thr.alive?
      if !o and @end_time.nil?
	 @end_time = Time.now
	 @script.unlink
      end
      o
   end
   def cmd
      pipe.to_s
   end
   def log
      File.read(log_path)
   end
   def log_path
      @logfile.path
   end
   def running_time
      end_time - start_time
   end

   private

      def call_task
	 o = EnveTask.class_variable_get(
		  "@@#{task.interpreter.upcase}").shellescape
	 o += " -f" if task.interpreter == "awk"
	 o += " " + File.expand_path(task.task, EnveJob.scripts).shellescape
      end
      
      def build_pipe
	 pipe = EnvePipe.new
	 if values.nil?
	    pipe.append(call_task, false)
	    pipe.append(task.help_arg, false) unless task.help_arg.nil?
	    return pipe
	 end
	 
	 pipe.last += call_task unless task.explicit_task?
	 task.each_option do |i,o|
	    if o.arg == :task
	       pipe.append(call_task, false)
	    elsif o.as_is?
	       psym = EnvePipe.PIPE_SYMBOL.key(o.opt)
	       psym.nil? ? pipe.append(o.opt, false) : pipe.add_ring(psym)
	    else
	       values[i] = values[i].map{ |v| v unless v.nil? or v=="" }.compact
	       if o.arg!=:nil and values[i].empty?
		  raise "#{o.name} is mandatory." if o.mandatory?
		  next
	       end
	       vals = case o.arg
		  # Flags
		  when :nil
		     values[i].map{ |v| o.opt.shellescape if v }.compact
		  # Numbers
		  when :integer, :float
		     pipe.append o.opt unless o.opt.nil?
		     values[i].map{ |v| o.arg==:integer ? v.to_i : v.to_f }
		  # Strings
		  when :character
		     pipe.append o.opt unless o.opt.nil?
		     values[i].map{ |v| v.to_s[0] }
		  else
		     pipe.append o.opt unless o.opt.nil?
		     values[i]
	       end
	       pipe.append(vals.join(o.multiple_sep), false)
	    end
	 end
	 return pipe
      end
end

class EnvePipe
   # Class-level
   @@PIPE_SYMBOL = {stderr:"2>", stdout:">", stderrout:"&>", stdin:"<", cmd:"|"}
   @@SPAWN_SYMBOL = {stderr: :err, stdout: :out, stdin: :in}
   def self.PIPE_SYMBOL; @@PIPE_SYMBOL; end
   def self.SPAWN_SYMBOL; @@SPAWN_SYMBOL; end
   # Instance-level
   attr_accessor :pipe, :type
   def initialize
      @pipe = [""]
      @type = [:cmd]
      @reserve = {stderr:false, stdout:false, stdin:false}
   end
   def [](i)	 @pipe[i] ; end
   def []=(i,v)	 @pipe[i] = v ; end
   def first()	 @pipe.first ; end
   def last()	 @pipe.last ; end
   def first=(v) @pipe[0] = v ; end
   def last=(v)	 @pipe[pipe.size-1] = v ; end
   def reserved?(type)
      @reserve[type.to_sym]
   end
   def reserve!(type)
      raise "Slot #{type} was previously reserved." if reserved? type
      @reserve[type.to_sym] = true
   end
   def unreserved
      return :stderrout unless reserved?(:stdout) or reserved?(:stderr)
      return :stderr unless reserved? :stderr
      return :stdout unless reserved? :stdout
      return nil
   end
   def append(v, escape=true)
      self.last += " " unless self.last==""
      self.last += (escape ? v.shellescape : v)
   end
   def add_ring(type=:cmd)
      @pipe << ""
      @type << type
      reserve!(:stderr) if type==:stderr or type==:stderrout
      reserve!(:stdout) if type==:stdout or type==:stderrout
      reserve!(:stdin)  if type==:stdin
   end
   def add_log(path)
      if unreserved.nil?
	 # No slot for log, just make an empty file
	 File.open(path, "w"){}
      else
	 add_ring unreserved
	 append path
      end
   end
   def to_open3_pipeline
      cmds = []
      opts = {}
      pipe.each_index do |i|
	 if type[i]==:cmd
	    cmds << pipe[i]
	 elsif type[i]==:stderrout
	    # For some reason this works from jruby but not from the jar:
	    opts[:err] = `echo #{pipe[i]}`.chomp
	    opts[:out] = `echo #{pipe[i]}`.chomp
	 elsif @@SPAWN_SYMBOL.keys.include? type[i]
	    opts[@@SPAWN_SYMBOL[type[i]]] = `echo #{pipe[i]}`.chomp
	 else
	    raise "Unsupported type: #{type[i]}."
	 end
      end
      cmds << opts
      cmds
   end
   def to_spawn
      cmds = to_open3_pipeline
      opts = cmds.pop
      [cmds.join(" | "), opts]
   end
   def to_s
      o = ""
      pipe.each_index do |i|
	 o += " " + @@PIPE_SYMBOL[type[i]] + " " unless i==0
	 o += pipe[i]
      end
      o
   end
end
