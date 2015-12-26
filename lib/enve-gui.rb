#
# @package enveomics
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
#

require "enve-collection"

if $IS_CLI
   require "shoes"
   require "shoes/swt"
   Shoes::Swt.initialize_backend
end

class EnveGUI < Shoes
   url "/", :home
   url "/index", :index
   url "/about", :about
   url "/update", :update
   url "/subcat-(.*--.*)", :subcat
   url "/script-(.*)", :script
   $img_path   = File.expand_path("../../img", __FILE__)
   $enve_jobs  = {}
   $citation   = [
      "Rodriguez-R and Konstantinidis. In preparation. The enveomics ",
      "collection: a toolbox for specialized analyses in genomics and ",
      "metagenomics."].join
   $gui_citation = [
      "The Graphical User Interface was developed on Shoes4 by ",
      "Luis M. Rodriguez-R [lmrodriguezr@gmail.com]. ",
      "Icons by Yu Luck from the Noun Project ",
      "[https://thenounproject.com/yuluck/uploads]."].join

   def self.init (&block)
      Shoes.app(title: "Enveomics | Everyday bioinformatics",
	 width: 750, height: 500, &block)
   end
   
   # =====================[ View : Windows ]
   # Main window
   def home
      header "/"
      stack(margin:[40,0,40,0]) do
	 title "Welcome to the Enveomics collection!", align:"center"
	 $home_info = para "Retrieving enveomics...", align:"center"
	 $manif_path = EnveCollection.manif
	 if $manif_path.nil?
	    zip_target = File.expand_path("master.zip", EnveCollection.home)
	    download EnveCollection.master_url,
	       save: zip_target,
	       finish: proc { |d|
		  $home_info.text = "Unzipping..."
		  # ToDo: Improve the next line!
		  system("cd #{EnveCollection.home.shellescape} " +
		     "&& unzip master.zip")
		  File.unlink(zip_target)
		  $manif_path = EnveCollection.manif
		  show_home
	       }
	 else
	    show_home
	 end
      end
      footer
   end
   
   # Index of all tasks
   def index
      header "/index"
      stack(margin:[40,0,40,0]) do
	 stack do
	    $collection.each_category do |cat_name, cat_set|
	       stack(margin: 20) do
		  subtitle cat_name
		  cat_set.each do |subcat_name, subcat_set|
		     stack(margin: 10) do
			para strong(subcat_name)
			show_subcat(subcat_set)
		     end # stack (subcategory)
		  end # each subcategory
	       end # stack (category)
	    end # each category
	 end # stack (collection)
      end # stack (main)
      footer
   end

   # Scripts per subcategory
   def subcat(subcatpath)
      (cat,subcat) = subcatpath.split("--")
      header
      stack(margin:[40,0,40,0]) do
	 title cat, " / ", subcat
	 cat_set = $collection.category(cat)
	 subcat_set = cat_set[subcat.to_sym]
	 show_subcat(subcat_set)
      end
      footer
   end

   # About enveomics
   def about
      header "/about"
      stack(margin:[40,0,40,0]) do
	 title "About the enveomics collection", align:"center"
	 para ""
	 subtitle "Citation"
	 edit_box $citation, width:1.0, height:60, state: "readonly"
	 para ""
	 subtitle "GUI Resources"
	 edit_box $gui_citation, width:1.0, height:60, state: "readonly"
      end
      footer
   end

   # Update enveomics
   def update
      FileUtils.rm_rf(File.dirname($manif_path))
      $manif_path = nil
      $collection = nil
      visit "/"
   end

   # Script query
   def script(task)
      header
      stack(margin:[40,0,40,0]) do
	 @t = $collection.task(task)
	 @opt_stack = []
	 #= Header
	 title @t.task
	 para @t.description, margin_left:7
	 show_task_warns @t
	 para "See also: ", *@t.see_also.map{ |s|
	       [link(s){visit "/script-#{s}" }, " "] }.flatten,
	       margin_left:7 unless @t.see_also.empty?
	 #= Options
	 @opt_elem  = []
	 show_task_options(@t)
	 #= Run!
	 show_task_run(@t)
      end # stack (task)
      footer
   end

   def show_home
      $home_info.text = "Loading collection..."
      $collection ||= EnveCollection.new($manif_path)
      $home_info.text = ""
      
      para ""
      flow(width:1.0) do
	 # (Sub)categories
	 stack(width:0.38) do
	    $collection.each_category do |cat, cat_set|
	       subtitle cat, align:"right"
	       inscription ""
	       cat_set.each do |subcat, subcat_set|
		  tagline link(subcat, click:"/subcat-#{cat}--#{subcat}"),
		     weight:"bold", align:"right"
		  para "#{subcat_set.count} tasks", align:"right"
		  inscription ""
	       end # each subcategory
	       para ""
	    end # each category
	 end # stack (collection)
	 # Separator
	 stack(width:0.04){}
	 # Sidebar for fun stuff
	 stack(width:0.58) do
	    subtitle "The most popular"
	    inscription ""
	    %w(ani.rb aai.rb FastQ.split.pl Taxonomy.silva2ncbi.rb
		     AlphaDiversity.pl).each do |t|
	       para strong(link(t, click:"/script-#{t}"), ": "),
		  $collection.task(t).description
	       inscription ""
	    end
	    para ""
	    subtitle "Some random suggestions"
	    inscription ""
	    $collection.tasks.sample(5).each do |t|
	       para strong(link(t.task, click:"/script-#{t.task}"), ": "),
		  t.description
	       inscription ""
	    end
	    para ""
	    subtitle "Citation"
	    inscription ""
	    para $citation
	    para ""
	    inscription ""
	    subtitle "GUI Resources"
	    inscription ""
	    para $gui_citation
	    para ""
	    inscription ""
	 end
      end # flow (the whole ordeal)
   end
   
   private

      # =====================[ View : Elements ]
      def header(in_page="")
	 self.scroll_top = 0
	 background pattern(img_path "bg1.png")
	 stack do
	    background rgb(0,114,179,0.4)
	    stack{ background rgb(0,0,0,1.0) } # workaround to shoes/shoes4#1190
	    flow(width:1.0) do
	       stack(width:40){}
	       menu = [
		  ["Home","/","noun_208357_cc.png"],
		  ["All tasks","/index","noun_208394_cc.png"],
		  ["Update","/update","noun_229107_cc.png"],
		  ["Website","http://enve-omics.ce.gatech.edu/",
		     "noun_208472_cc.png"],
		  ["About","/about","noun_229118_cc.png"]
	       ]
	       menu.each do |i|
		  flow(width:60, height:65) do
		     if i[1]==in_page
			background rgb(0,114,179,0.4)
			stack{ background rgb(0,0,0,1.0) } # shoes/shoes4#1190
		     end
		     stack(width:5, height:50){}
		     stack(width:50) do
			image img_path((i[1]==in_page ? "w-" : "")+i[2]),
			   width:50, height:50, margin:2
			inscription i[0], align:"center",
			   size:(linux? ? 8 : 10),
			   stroke: (i[1]==in_page ? white : black)
		     end
		     stack(width:5){}
		  end.click{ (i[1]=~/^https?:/) ? open_url(i[1]) : visit(i[1]) }
		  stack(width:5){}
	       end
	    end
	    stack(height:5, width:1.0){}
	    stack(height:2, width:1.0) { background black }
	 end
	 stack(height:20, width:1.0){}
      end

      def footer
	 para "", margin:50
      end
      
      def show_subcat(subcat_set)
	 subcat_set.each do |t_name|
	    t = $collection.task(t_name)
	    if t.nil?
	       para t_name, stroke: "#777", margin: 5
	    else
	       para link(t.task, click: "/script-#{t.task}"),
		  ": ", t.description, margin: 5
	    end
	 end # each task
      end

      def show_task_warns(task)
	 return if task.warn.empty? if task.ready?
	 para ""
	 stack(margin:[50,0,50,0]) do
	    background "#fdd"..."#f99"
	    border "#300"
	    stack(margin:[20,0,20,0]) do
	       para ""
	       if not task.ready?
		  para strong("This script cannot be used due to unmet" +
		     " requirements:")
		  task.unmet.each do |r|
		     p = [r.description]
		     p += [" (",link("get"){ open_url r.source_url},")"] if
			not r.source_url.nil?
		     p << "."
		     para *p, margin:[10,0,10,0]
		  end
		  para ""
	       end
	       unless task.warn.empty?
		  para strong("Warning")
		  para task.warn, margin:[10,0,10,0]
		  para ""
	       end
	    end
	 end
	 para ""
      end

      def show_task_options(task)
	 #= Show/Hide optional parameters
	 # FIXME This code is redundant and uggly:
	 @button_show = button("Show optional parameters", hidden:true) do
	    task.each_option do |i,o|
	       next if @opt_stack[i].nil?
	       @opt_stack[i].toggle unless o.mandatory?
	    end
	    @button_hide.toggle
	    @button_show.toggle
	 end
	 @button_hide = button("Hide optional parameters") do
	    task.each_option do |i,o|
	       next if @opt_stack[i].nil?
	       @opt_stack[i].toggle unless o.mandatory?
	    end
	    @button_hide.toggle
	    @button_show.toggle
	 end
	 para "", margin:10
	 #= Each option
	 @opt_plus_button = []
	 task.each_option do |opt_i, opt|
	    next if opt.hidden?
	    @opt_elem[opt_i] = []
	    @opt_stack[opt_i] = stack(margin:[10,0,10,0]) do
	       subtitle opt.name
	       para opt.description if opt.description and opt.arg!=:nil
	       @opt_plus_button[opt_i] = stack do
		  show_task_option(opt, opt_i)
	       end
	       button("+") do
		  @opt_plus_button[opt_i].append do
		     show_task_option(opt, opt_i)
		  end
	       end unless opt.multiple_sep.nil?
	       inscription opt.note if opt.note
	       opt.source_urls.each{ |url| para link(url){ open_url(url) } }
	       para "", margin:10
	    end # stack (option)
	 end # each_option
	 para strong("* Required"), margin:[10,0,10,0]
	 para ""
      end

      def show_task_option(opt, opt_i)
	 case opt.arg
	    when :nil
	       show_task_option_check(opt, opt_i)
	    when :in_file,:out_file,:in_dir,:out_dir
	       show_task_option_file(opt, opt_i)
	    when :select
	       show_task_option_select(opt, opt_i)
	    when :string, :integer, :float
	       show_task_option_edit(opt, opt_i)
	 end
      end
      def show_task_option_check(opt, opt_i)
	 flow do
	    @opt_elem[opt_i] << check
	    para opt.description if opt.description
	 end
      end

      def show_task_option_select(opt, opt_i)
	 @opt_elem[opt_i] << list_box(items: opt.values)
      end

      def show_task_option_edit(opt, opt_i)
	 @opt_elem[opt_i] << edit_line(opt.default)
      end

      def show_task_option_file(opt, opt_i)
	 opt_j = @opt_elem[opt_i].size
	 flow do
	    b_t = {in_file: "Open file", out_file: "Save as",
	       in_dir: "Open folder", out_dir: "Save folder as"}
	    button(b_t[opt.arg]) do
	       file = opt.arg==:in_file ? Shoes.ask_open_file :
		  opt.arg==:out_file ? Shoes.ask_save_file :
		  opt.arg==:in_dir ? Shoes.ask_open_folder :
		  Shoes.ask_save_folder
	       unless file.nil?
		  @opt_elem[opt_i][opt_j].text = file
	       end
	    end
	    @opt_elem[opt_i] << edit_line("")
	 end
      end

      def show_task_run(task)
	 flow do
	    button("Execute") do
	       @values = []
	       task.each_option do |opt_i, opt|
		  next if @opt_elem[opt_i].nil?
		  @values[opt_i] = @opt_elem[opt_i].map { |e|
		     e.is_a?(Check) ? e.checked? : e.text
		  }
	       end
	       launch_analysis(task, @values)
	    end
	    button("Reset defaults"){ visit "/script-#{task}" }
	    unless task.hash[:help_arg].nil?
	       button("Embedded help") do
		  launch_analysis(task, nil)
	       end
	    end
	 end
      end

      # =====================[ Controller : Tasks / Helpers ]
      def launch_analysis(t, values)
	 begin
	    window(title: "Running #{t.task}", width: 750, height: 512) do
	       background "#B2E5F4" .. "#F1E1F4"
	       @job = t.launch_job(values)
	       stack(margin:30, width:1.0) do
		  subtitle t.task
		  para strong("Command:")
		  edit_box @job.cmd, width:1.0, height:40, state:"readonly"
		  para ""
		  para strong("Start time: "), @job.start_time.ctime
		  para strong("Log: "), @job.log_path
		  @running = edit_box "", state:"readonly",
					     width:1.0, height: 275
		  animate(4) do |frame|
		     unless @running.nil?
			@running.text = @job.log
			if @job.alive?
			   @running.text += "\n#{@job.status}"+("."*(frame%4))
			else
			   para ""
			   para strong("Running time: "),@job.running_time,"s."
			   @running = nil
			end
		     end
		  end
	       end
	    end
	 rescue => e
	    Shoes.alert "#{e}\n\n#{e.backtrace.first}"
	 end
      end
      
      # =====================[ Controller : Misc / Helpers ]
      def img_path(img)
	 # Easy peasy for normal files
	 o = File.expand_path(img, $img_path)
	 return o if __FILE__ !~ /\.jar!\//
	 # Juggling around packages:
	 h = File.expand_path(img, EnveCollection.home)
	 FileUtils.copy(o, h) unless File.exist? h
	 h
      end

      def open_url(url)
	 if windows?
	    system("start #{url}")
	 elsif mac?
	    system("open #{url}")
	 elsif linux?
	    # I added ' &', so it doesn't block
	    system("xdg-open #{url} &")
	 end
      end

      def linux?
	 RbConfig::CONFIG['host_os'] =~ /linux|bsd/
      end

      def windows?
	 RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      end

      def mac?
	 RbConfig::CONFIG['host_os'] =~ /darwin/
      end
end
