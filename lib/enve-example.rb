class EnveExample
   attr_accessor :description, :task, :values
   def initialize(hash, collection)
      hash.each{ |k,v| instance_variable_set("@#{k}", v) }
      @task = collection.task(task)
      @description ||= "Example of #{task.task}."
      @description = description.join(" ") if description.is_a? Array
      @values ||= []
      @values = values.map{ |i| i.is_a?(Array) ? i : [i] }
      raise "The task #{task.task} has #{task.options.count} options, but "+
	 "the example has #{values.count} values." unless
	 values.count == task.options.count
   end
end
