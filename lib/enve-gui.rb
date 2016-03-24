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
   url "/examples", :examples
   url "/update", :update
   url "/about", :about
   url "/subcat/(.*/.*)", :subcat
   url "/script/(.+)", :script
   url "/example/(\\d+)", :example
   $current_loc = "/"
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
      $current_loc = "/"
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
      $current_loc = "/index"
      header "/index"
      stack(margin:[40,0,40,0]) do
	 stack do
	    $collection.each_category do |cat_name, cat_set|
	       stack(margin: 20) do
		  subtitle cat_name
		  cat_set.each do |subcat_name, subcat_set|
		     stack(margin: 10) do
			tagline subcat_name
			show_subcat(subcat_set)
		     end # stack (subcategory)
		  end # each subcategory
	       end # stack (category)
	    end # each category
	 end # stack (collection)
      end # stack (main)
      footer
   end

   # Examples
   def examples
      $current_loc = "/examples"
      header "/examples"
      para ""
      stack(margin:[40,0,40,0]) do
	 $collection.examples.each_index do |i|
	    box(click:"/example/#{i}") do
	       e = $collection.examples[i]
	       para e.description, margin_left:10, margin_right:10, size:15
	       para "Using ", e.task.task, ".", margin_right:10, align:"right"
	    end
	 end unless $collection.examples.nil?
      end
      footer
   end

   # About enveomics
   def about
      $current_loc = "/about"
      header "/about"
      stack(margin:[40,0,40,0]) do
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
      $current_loc = "/update"
      FileUtils.rm_rf(File.dirname($manif_path))
      $manif_path = nil
      $collection = nil
      visit "/"
   end

   # Script query
   def script(task, example=nil)
      $current_loc = "/script/#{task}" if example.nil?
      header
      stack(margin:[40,0,40,0]) do
	 $t = $collection.task(task)
	 $opt_stack = []
	 #= Header
	 unless example.nil?
	    box do
	       para strong("Test example:")
	       para $example.description, left_margin:20, right_margin:20
	       para "Parameters highlighted in blue have been changed from ",
	         "the defaults (", link("reload defaults"){
		    visit "/script/#{$example.task.task}" },").",
		 left_margin:20, right_margin:20
	    end
	    para ""
	 end
	 title $t.task
	 para $t.description, margin_left:7
	 show_task_warns $t
	 show_task_cites $t
	 para "See also: ", *$t.see_also.map{ |s|
	       [link(s){visit "/script/#{s}" }, " "] }.flatten,
	       margin_left:7 unless $t.see_also.empty?
	 #= Options
	 $opt_elem  = []
	 show_task_options($t)
	 #= Run!
	 show_task_run($t)
      end # stack (task)
      footer
   end

   # Load an example
   def example(index)
      $current_loc = "/example/#{index}"
      $example = $collection.examples[index.to_i]
      script($example.task.task, $example)
      fill_task_values($example.values)
   end

   # Generic helper
   def box(opts={}, &blk)
      flow(margin_bottom:5) do
	 opts[:alpha] ||= 0.2
	 opts[:side_line] ||= enve_blue
	 opts[:background] ||= enve_blue(opts[:alpha])
	 stack(width: 5, height: 1.0) do
	    background opts[:side_line]
	 end unless opts[:right]
	 stack(width: -5) do
	    background opts[:background]
	    s = stack(margin:5, &blk)
	    unless opts[:click].nil?
	       s.click{ visit opts[:click] }
	       $clicky << s
	    end
	 end
	 stack(width: 5, height: 1.0) do
	    background opts[:side_line]
	 end if opts[:right]
      end
   end

   def enve_blue(alpha=1.0)
      rgb(0,114,179,alpha)
   end

   def enve_red(alpha=1.0)
      rgb(179,0,3,alpha)
   end

   private

      # =====================[ View : Elements ]
      def header(in_page="")
	 # workaround to shoes/shoes4#1212:
	 $clicky ||= []
	 $clicky.each{ |i| i.hide }
	 $clicky = []
	 
	 # Header
	 self.scroll_top = 0
	 background pattern(img_path "bg1.png")
	 stack do
	    background enve_blue(0.4)
	    stack{ background rgb(0,0,0,1.0) } # workaround to shoes/shoes4#1190
	    flow(width:1.0) do
	       stack(width:40){}
	       menu = [
		  ["Home","/","noun_208357_cc.png"],
		  ["All tasks","/index","noun_208394_cc.png"],
		  ["Examples","/examples","noun_229087_cc.png"],
		  ["Update","/update","noun_229107_cc.png"],
		  ["Website","http://enve-omics.ce.gatech.edu/",
		     "noun_208472_cc.png"],
		  ["About","/about","noun_229118_cc.png"]
	       ]
	       menu.each do |i|
		  flow(width:60, height:65) do
		     if i[1]==in_page
			background enve_blue(0.4)
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
	 stack(height:40){}.parent
	 stack do
	    stroke enve_blue
	    flow do
	       stack(height:2, width:0.25){}
	       stack(height:2, width:0.5){ background enve_blue }
	    end
	    stack(margin:10) do
	       inscription "Developed by ", link("Luis M. Rodriguez-R"){
			   open_url "https://lmrodriguezr.github.io"}, " at ",
		  link("Kostas lab"){open_url "http://enve-omics.gatech.edu/"},
		  ".", align:"center"
	    end
	    stroke black
	 end
      end
      
      def show_home
	 $home_info.text = "Loading collection..."
	 $collection ||= EnveCollection.new($manif_path)
	 $home_info.text = ""
	 
	 para ""
	 flow(width:1.0) do
	    # (Sub)categories side menu
	    stack(width:0.23) do
	       $collection.each_category do |cat, cat_set|
		  box(alpha:0.7, right:true) do
		     tagline cat, align:"right", stroke: white
		  end
		  cat_set.each do |subcat, subcat_set|
		     box(click:"/subcat/#{cat}/#{subcat}",right:1,alpha:0.45) do
			para strong(subcat), margin_bottom:2, align:"right"
			para "#{subcat_set.count} scripts", align:"right"
		     end
		  end # each subcategory
		  para ""
	       end # each category
	    end # stack (collection)
	    # Separator
	    stack(width:0.04){}
	    # Highlights
	    stack(width:0.73) do
	       show_search_bar
	       $default_home = stack(width:1.0) do
		  subtitle "The most popular"
		  inscription ""
		  %w(ani.rb aai.rb FastQ.split.pl Taxonomy.silva2ncbi.rb
			   AlphaDiversity.pl).each do |t|
		     show_task_link($collection.task(t))
		  end
		  para ""
		  subtitle "Some random suggestions"
		  inscription ""
		  $collection.tasks.sample(5).each do |t|
		     show_task_link(t)
		  end
	       end
	    end
	 end # flow (the whole ordeal)
      end # show_home

      def show_search_bar
	 flow(width:1.0) do
	    stack(width:29, height:29) do
	       background enve_blue
	       image img_path("w-noun_208368_cc.png"),
		  width:25, height:25, left:2, top:2
	    end
	    $last_search = ""
	    edit_box("", width:-29, height:29).change do |ln|
	       ln.text = ln.text.gsub(/[\n\r]/,"") if ln.text=~/[\n\r]/
	       timer(1) do
		  if $last_search == ln.text
		     # Do nothing
		  elsif ln.text.length < 2
		     $default_home.show
		     $search_results.clear
		  else
		     $default_home.hide
		     $search_results.clear
		     $search_results.append do
			$collection.search(ln.text).each do |k, res|
			   box(click: res.id) do
			      para strong res.name
			      para res.description
			   end
			end
		     end
		  end
		  $last_search = ln.text
	       end
	    end
	 end
	 para ""
	 $search_results = stack {}
      end
      
      def subcat(subcatpath)
	 (cat,subcat) = subcatpath.split("/")
	 header
	 stack(margin:[40,0,40,0]) do
	    tagline cat, " / ", subcat
	    cat_set = $collection.category(cat)
	    subcat_set = cat_set[subcat.to_sym]
	    show_subcat(subcat_set)
	 end
	 footer
      end

      def show_subcat(subcat_set)
	 subcat_set.each do |t_name|
	    t = $collection.task(t_name)
	    show_task_link(t) unless t.nil?
	 end
      end

      def show_task_link(task)
	 box(click:"/script/#{task.task}") do
	    para strong(task.task), margin_bottom:2
	    para task.description
	 end
      end

      def show_task_warns(task)
         return if task.warn.empty? and task.ready?
	 stack(margin:10) do
	    box(background:enve_red(0.3), side_line:enve_red) do
	       if not task.ready?
		  para strong("This script cannot be used due to unmet" +
		     " requirements:"), margin_bottom:2
		  task.unmet.each do |r|
		     p = [r.description]
		     p += [" ("] unless r.solution.nil? and r.source_url.nil?
		     p += [link("auto-install"){
			   Shoes.alert("attempting installation...")
			   r.resolve or alert("Installation failed.")
			   visit $current_loc
			}] if not r.solution.nil?
		     p += [" or "] unless r.solution.nil? or r.source_url.nil?
		     p += [link("get"){ open_url r.source_url},")"] if
			not r.source_url.nil?
		     p << "."
		     para *p, margin:[10,0,10,0]
		  end
		  para "" unless task.warn.empty?
	       end
	       unless task.warn.empty?
		  para strong("Warning"), margin_bottom:2
		  para task.warn, margin:[10,0,10,0]
	       end
	    end
	 end
      end

      def show_task_cites(task)
         return if task.cite.empty?
         stack(margin:10) do
            box(background:enve_blue(0.3), side_line:enve_blue) do
               p = ["If you use this script, also cite"]
               task.cite.each do |ref|
                  p += [" (", link(ref[0]){ open_url ref[1] }, ")"]
               end
               para *p, ".", margin:[10,0,10,0]
            end
         end
      end

      def show_task_options(task)
	 #= Show/Hide optional parameters
	 @button_show_hide = button("Hide optional parameters") do
	    task.each_option do |i,o|
	       next if $opt_stack[i].nil?
	       $opt_stack[i].toggle unless o.mandatory?
	    end
	    @button_show_hide.text = (@button_show_hide.text =~ /^Hide/ ?
	       "Show optional parameters" : "Hide optional parameters")
	 end
	 para "", margin:10
	 #= Each option
	 @opt_plus_button = []
	 task.each_option do |opt_i, opt|
	    next if opt.hidden?
	    $opt_elem[opt_i] = []
	    $opt_stack[opt_i] = stack(margin:10) do
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
	    $opt_elem[opt_i] << check
	    para opt.description if opt.description
	 end
      end

      def show_task_option_select(opt, opt_i)
	 $opt_elem[opt_i] << list_box(items: opt.values)
	 $opt_elem[opt_i].last.choose(opt.default) unless opt.default.nil?
      end

      def show_task_option_edit(opt, opt_i)
	 $opt_elem[opt_i] << edit_line(opt.default)
      end

      def show_task_option_file(opt, opt_i)
	 opt_j = $opt_elem[opt_i].size
	 flow do
	    b_t = {in_file: "Open file", out_file: "Save as",
	       in_dir: "Open folder", out_dir: "Save folder as"}
	    button(b_t[opt.arg]) do
	       file = opt.arg==:in_file ? Shoes.ask_open_file :
		  opt.arg==:out_file ? Shoes.ask_save_file :
		  opt.arg==:in_dir ? Shoes.ask_open_folder :
		  Shoes.ask_save_folder
	       unless file.nil?
		  $opt_elem[opt_i][opt_j].text = file
	       end
	    end
	    $opt_elem[opt_i] << edit_line("")
	 end
      end

      def show_task_run(task)
	 flow do
	    button("Execute") do
	       @values = []
	       task.each_option do |opt_i, opt|
		  next if $opt_elem[opt_i].nil?
		  @values[opt_i] = $opt_elem[opt_i].map { |e|
		     e.is_a?(Check) ? e.checked? : e.text
		  }
	       end
	       launch_analysis(task, @values)
	    end
	    button("Reset defaults"){ visit "/script/#{task}" }
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

      def fill_task_values(values)
	 $out_dir = nil
	 $in_dir = File.expand_path("enveomics-master/Tests",EnveCollection.home)
	 $t.each_option do |opt_i, opt|
	    opt_j = -1
	    values[opt_i].each do |v|
	       next if v.nil?
	       opt_j += 1
	       # Create new slots if necessary
	       if $opt_elem[opt_i].size-1 < opt_j
		  @opt_plus_button[opt_i].append do
		     show_task_option(opt, opt_i)
		  end
	       end
	       # Fill it
	       case opt.arg
		  when :nil
		     $opt_elem[opt_i][opt_j].checked = v
		  when :in_file,:in_dir
		     $opt_elem[opt_i][opt_j].text = File.expand_path(v,$in_dir)
		  when :out_file,:out_dir
		     while $out_dir.nil?
			Shoes.alert("Please select an output folder.")
			$out_dir = Shoes.ask_save_folder
		     end
		     $opt_elem[opt_i][opt_j].text = File.expand_path(v,$out_dir)
		  when :select
		     $opt_elem[opt_i][opt_j].choose(v)
		  when :string, :integer, :float
		     $opt_elem[opt_i][opt_j].text = v
	       end
	       # Visually document the change
	       $opt_stack[opt_i].prepend do
		  background enve_blue(0.2)
	       end
	    end # values.each
	 end # each_option
      end
      
      # =====================[ Controller : Misc / Helpers ]
      def img_path(img)
	 # Easy peasy for normal files
	 o = File.expand_path(img, $img_path)
	 return o if __FILE__ !~ /\.jar!\//
	 # Juggling around packages:
	 idir = File.expand_path("img", EnveCollection.home)
	 Dir.mkdir(idir) unless Dir.exist? idir
	 h = File.expand_path(img, idir)
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
