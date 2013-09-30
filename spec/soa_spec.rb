require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path('../recipes/fake_recipe', __FILE__)
describe Capistrano::Ext::SOA, "loaded into a configuration" do
  before do
    @configuration = Capistrano::Configuration.new
    
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    config_root = "/opt/deploy"

    File.stub(:expand_path) {config_root}
    @project_dir = ["a/b/production.rb", "a/b/staging.rb", "a/b.rb", "a/c/staging.rb"]

    Dir.stub(:[]) {@project_dir.map {|dir| "#{config_root}/#{dir}"}}
    @configuration.extend(Capistrano::Fakerecipe)
    Capistrano::Fakerecipe.load_into(@configuration)
    Capistrano::Ext::SOA.load_into(@configuration)
    @stages = ["production", "staging"]
    @services = ["a:b", "a:c"]
  end

  it "should define correct tasks" do
    @configuration.find_task('a:b:production').should_not == nil
    @configuration.find_task('a:b:staging').should_not == nil
    @configuration.find_task('a:c:staging').should_not == nil
    @configuration.find_task('a:c:production').should == nil
    @configuration.find_task('soa:ensure').should_not == nil
  end

  it "should use default stage if not stage define" do
    @configuration.set :default_stage, 'staging'
    @configuration.find_task('a:c').should_not == nil
    @configuration.find_task('world:staging:deploy')
  end

  it "should parse with stage only args" do
    args = ["staging"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should be_empty
    selected_stage.should == "staging"
    task.should == nil
  end

  it "should parse single stage with one service and different environment" do
    args = ["staging", "a:b", "a:b:production"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b"]
    selected_stage.should == "staging"
    task.should == nil
  end

  it "should parse default stage with two services" do
    args = ["a:b", "a:c"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == nil
    task.should == nil
  end

  it "should one or more services with undefined environment" do
    args = ["a:b:integration", "a:c"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == nil
    task.should == nil
  end

  it "should one or more services with differnt environment" do
    args = ["a:b:staging", "a:c"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == "staging"
    task.should == nil
  end

  it "should parse multiple service and different default and specific environment" do
    args = ["staging", "a:b", "a:c:production"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == "staging"
    task.should == nil
  end

  it "should parse multiple services with different specific environments" do
    args = ["a:b:staging", "a:c:production"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == "staging"
    task.should == nil
  end

  it "should parse multiple services with one specific environment" do
    args = ["a:b", "a:c:production"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == "production"
    task.should == nil
  end

  it "should parse default environment, service and task" do
    args = ["staging","a:b", "deploy:start"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b"]
    selected_stage.should == "staging"
    task.should == "deploy:start"
  end

  it "should parse default stage and one service" do
    args = ["staging","a:b", "deploy:start", "a:d"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b"]
    selected_stage.should == "staging"
    task.should == "deploy:start a:d"
  end

  it "should parse one stage, multiple services and task" do
    args = ["staging","a:b", "a:d", "deploy:start"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b"]
    selected_stage.should == "staging"
    task.should == "a:d deploy:start"
  end

  it "should parse one stage, multiple services and task" do
    args = ["staging","a:b", "a:c", "deploy:start"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == "staging"
    task.should == "deploy:start"
  end

  it "should parse single stage with one or more services" do
    args = ["staging","world", "deploy:start"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == "staging"
    task.should == "deploy:start"
  end

  it "should parse single stage with one or more services" do
    args = ["world:staging", "deploy:start"]
    selected_stage, selected_services, task = @configuration.parse_args(args, @stages, @services)
    selected_services.should == ["a:b", "a:c"]
    selected_stage.should == "staging"
    task.should == "deploy:start"
  end

  it "should build task with multiple services" do
    stage = "staging"
    services = ["a:b", "a:c"]
    task = "fake:thing"

    @configuration.build_task(stage, services, task)
    @configuration.find_task("fake:al_thing").should_not be_nil
    @configuration.find_task("fake:thing").should_not be_nil
  end

  it "should build multiple task with multiple services" do
    stage = "staging"
    services = ["a:b", "a:c"]
    task = "fake:thing fake:foo"

    @configuration.build_task(stage, services, task)
    @configuration.find_task("fake:al_thing").should_not be_nil
    @configuration.find_task("fake:thing").should_not be_nil

    @configuration.find_task("fake:al_foo").should_not be_nil
    @configuration.find_task("fake:foo").should_not be_nil
  end



  # it "should run one stage and service on load" do
  #   args = ["staging"]
  #   ARGV = args
  #   @configuration.trigger(:load)
  #   @configuration.fetch(:stage).should == "staging"
  #   @configuration.fetch(:services).should == []
  # end

  # it "should build a task for services" do
  #   @configuration.stub(:services).and_return(["a:b", "a:c"])

  #   @configuration.build_task("staging", ["a:b", "a:c"],"fake:thing")
    
  #   @configuration.find_task("fake:_thing").should_not == nil
  #   @configuration.find_task("fake:thing").should_not == nil

  #   @configuration.find_and_execute_task("fake:thing")
  #   @configuration.fetch(:bar).should == "baz"
  # end
end
