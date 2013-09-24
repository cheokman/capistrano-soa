require 'capistrano'
require 'fileutils'
require 'colored'

module Capistrano::Ext
  module SOA
    def get_config_files(config_root)
      config_files = Dir["#{config_root}/**/*.rb"]
      config_files.reject! do |config_file|
          config_dir = config_file.gsub(/\.rb$/, '/')
          config_files.any? { |file| file[0, config_dir.size] == config_dir }
      end
      config_files
    end

    def collect_stages(config_files)
      config_files.map {|f| File.basename(f, ".rb")}.uniq
    end

    def get_config_names(config_files, config_root)
      config_names = config_files.map do |config_file|
        config_file.sub("#{config_root}/", '').sub(/\.rb$/, '').gsub('/', ':')
      end
    end

    def get_services_name(config_names)
      services_name = []
      config_names.each do |config_name|
        services_name << extract_service_name(config_name)
      end
      services_name
    end

    def extract_service_name(config_name)
      segments = config_name.split(':')
      segments[0, segments.size - 1].join(':')
    end

    def get_service_name(config_name, services)
      if services.include?(config_name)
        config_name
      else
        segments = config_name.split(':')
        if segments.size > 1
          possible_service_name = (segments[0, segments.size - 1].join(':'))
        else
          possible_service_name = segments[0]
        end
        if services.include?(possible_service_name)
          possible_service_name
        elsif possible_service_name == "world"
          services.dup
        else
          nil
        end
      end
    end

    def get_stage_name(config_name, stages)
      possible_stage_name = config_name.split(':').last
      stages.include?(possible_stage_name) ? possible_stage_name : nil
    end

    #
    # One Environment with different applications deployment
    # cap integration prj0:subprj0:app0 prj1:subprj0:app1 deploy
    # cap prj0:subprj0:app0:integration prj0:subprj0:app0:integration deploy
    #
    # One environment with one application
    # cap prj0:subprj0:app0:integration deploy
    #
    # Different Environments with different applications deployment
    # cap prj0:subprj0:app0:integration prj0:subprj0:app0:staging deploy
    #

    def parse_args(args, stages, services)
      args = args.dup
      selected_services = []
      tasks = nil
      selected_stage = nil

      selected_stage = if stages.include?(args.first)
                args.shift
              elsif !get_stage_name(args.first, stages).nil?
                arg = args.shift
                selected_services << get_service_name(arg, services)
                get_stage_name(arg, stages)
              else
                nil
              end

      args.each_with_index do |a, i|
        if selected_stage.nil? && !get_stage_name(a, stages).nil?
          selected_stage = get_stage_name(a, stages)
          _service = get_service_name(a, services)
          selected_services << _service unless selected_services.include?(_service)
        elsif !get_service_name(a, services).nil?
          _service = get_service_name(a, services)
          selected_services << _service unless selected_services.include?(_service)
        else
          tasks = args[i..args.length].join(" ")
          break
        end
      end
      [selected_stage, selected_services.flatten.uniq, tasks]
    end

    def build_task(stage, services, this_task)

      if services.size > 1
        segments = this_task.split(':')
        if segments.size > 1
          namespace_names = segments[0, segments.size-1]
          task_name = segments.last
        else
          namespace_names = [segments[0]]
          task_name = "default"
        end
        
        block = lambda do |parent|
          alias_task "_#{task_name}".to_sym, task_name.to_sym

          task(task_name) do
            services.each do |service|
              system("cap #{stage} #{service} _#{task_name}")
            end
          end  
        end

        block = namespace_names.reverse.inject(block) do |child, name|
          lambda do |parent|
            parent.namespace(name, &child)
          end
        end
        block.call(top)
      end
    end

    def self.load_into(configuration)
      configuration.extend self

      configuration.load do
        config_root = File.expand_path(fetch(:config_root, "config/deploy"))

        #config_files = Dir["#{config_root}/**/*.rb"]
        config_files = get_config_files(config_root)
        
        set :stages, collect_stages(config_files) unless exists?(:stages)

        # build configuration names list
        config_names = get_config_names(config_files,config_root)

        config_names.each do |config_name|
          config_name.split(':').each do |segment|
            if all_methods.any? { |m| m == segment }
              raise ArgumentError, "Config task #{config_name} name overrides #{segment.inspect} (method|task|namespace)"
            end
          end
        end

        stages.each do |s|
          desc "Set the target stage to `#{s}'."

          task(s.to_sym) do
            top.set :stage, s.to_sym
          end
        end

         # create configuration task for each configuration name
        config_names.each do |config_name|
          segments = config_name.split(':')
          namespace_names = segments[0, segments.size - 1]
          task_name = segments.last

          # create configuration task block.
          # NOTE: Capistrano 'namespace' DSL invokes instance_eval that
          # that pass evaluable object as argument to block.
          block = lambda do |parent|
            task(:default) do
              default_segment = segments[0, segments.size - 1]
              default_segment << fetch(:stage)
              default_segment.size.times do |i|
                path = ([config_root] + default_segment[0..i]).join('/') + '.rb'
                top.load(:file => path) if File.exists?(path)
              end
            end

            desc "Load #{config_name} configuration"
            task(task_name) do
              # set configuration name as :config_name variable
              top.set :config_name, config_name

              #set :stage, task_name.to_sym
              # recursively load configurations
              segments.size.times do |i|
                path = ([config_root] + segments[0..i]).join('/') + '.rb'
                top.load(:file => path) if File.exists?(path)
              end
            end
          end

          # wrap task block into namespace blocks
          #
          # namespace_names = [nsN, ..., ns2, ns1]
          #
          # block = block0 = lambda do |parent|
          #   desc "DESC"
          #   task(:task_name) { TASK }
          # end
          # block = block1 = lambda { |parent| parent.namespace(:ns1, &block0) }
          # block = block2 = lambda { |parent| parent.namespace(:ns2, &block1) }
          # ...
          # block = blockN = lambda { |parent| parent.namespace(:nsN, &blockN-1) }
          #
          block = namespace_names.reverse.inject(block) do |child, name|
            lambda do |parent|
              parent.namespace(name, &child)
            end
          end

          # create namespaced configuration task
          #
          # block = lambda do
          #   namespace :nsN do
          #     ...
          #     namespace :ns2 do
          #       namespace :ns1 do
          #         desc "DESC"
          #         task(:task_name) { TASK }
          #       end
          #     end
          #     ...
          #   end
          # end
          block.call(top)
        end

       STDOUT.sync
        before "deploy:update_code" do
            print "Updating Code........ "
            start_spinner()
        end

        after "deploy:update_code" do
            stop_spinner()
            puts "Done.".green
        end

        before "deploy:cleanup" do
            print "Cleaning Up.......... "
            start_spinner()
        end

        after "deploy:restart" do
            stop_spinner()
            puts "Done.".green
        end

        before "deploy:restart" do
            print "Restarting .......... "
            start_spinner()
        end

        after "deploy:cleanup" do
            stop_spinner()
            puts "Done.".green
        end
        # spinner stuff
        @spinner_running = false
        @chars = ['|', '/', '-', '\\']
        @spinner = Thread.new do
          loop do
            unless @spinner_running
              Thread.stop
            end
            print @chars[0]
            sleep(0.1)
            print "\b"
            @chars.push @chars.shift
          end
        end

        def start_spinner
          @spinner_running = true
          @spinner.wakeup
        end

        # stops the spinner and backspaces over last displayed character
        def stop_spinner
          @spinner_running = false
          print "\b"
        end

        on :load do
          services_name = get_services_name(config_names)

          selected_stage, selected_services, selected_task = parse_args(ARGV, stages, services_name)

          set :stage, selected_stage
          set :services, selected_services
          build_task(selected_stage, selected_services, selected_task)
     
          if stages.include?(stage)
            # Execute the specified stage so that recipes required in stage can contribute to task list
            tsk = stage
            tsk = "#{services.first}:#{tsk}" if services.first
            find_and_execute_task(tsk)# if ARGV.any?{ |option| option =~ /-T|--tasks|-e|--explain/ }
          else
            # Execute the default stage so that recipes required in stage can contribute tasks
            if exists?(:default_stage)
              tsk = default_stage
              tsk = "#{services.first}:#{tsk}" if services.first
              find_and_execute_task(tsk) 
            end
          end
        end

        namespace :soa do
           desc "[internal] Ensure that a stage has been selected."
           task :ensure do
             if !exists?(:stage)
               if exists?(:default_stage)
                 logger.important "Defaulting to `#{default_stage}'"
                 find_and_execute_task("#{ARGV.first}:#{default_stage}")
               else
                 abort "No stage specified. Please specify one of: #{stages.join(', ')} (e.g. `cap #{stages.first} #{ARGV.last}')"
               end
             end
           end
        end
        
        set(:config_names, config_names)

        on :start, "soa:ensure"

        def service_list_from(services)
          services = services.split(',') if String == services
          services.reject {|s| !services_name.include?(s)}
        end

        def find_soa_stages(stage)
          unless ENV["SRVS"].nil?
            services = services_list_from(ENV["SRVS"]) 
          else
            services = services_name
          end
        end

        task(:world) do
        end

        # namespace :world do
        #   stages.each do |stage|
        #     namespace stage.to_sym do
        #       task :deploy do
        #       end
        #     end
        #   end
        # end
      end

    end

  end
end

unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/soa require Capistrano 2"
end

if Capistrano::Configuration.instance
  Capistrano::Ext::SOA.load_into(Capistrano::Configuration.instance)
end
