require 'capistrano'
  module Capistrano
    module Fakerecipe
      def self.load_into(configuration)
        configuration.load do
          before "fake:before_this_execute_thing", "fake:thing"
          before "fake:before_this_also_execute_thing", "fake:thing"
          after "fake:after_this_execute_thing", "fake:thing"
          after "fake:after_this_also_execute_thing", "fake:thing"
          namespace :fake do
            namespace :inner_fake do
              task :inner_thing do
                run ('do inner some stuff')
              end
            end
            desc "foo and run foo"
            task :foo do
              set :cool, "cool"
            end
            desc "thing and run fake manifests"
            task :thing do
              set :bar, "baz"
              run('do some stuff')
              upload("foo", "/tmp/foo")
              get('/tmp/baz', 'baz')
              put('fake content', '/tmp/put')
            end
            desc "More fake tasks!"
            task :before_this_execute_thing do
              #
            end
            desc "You get the picture..."
            task :before_this_also_execute_thing do
              #
            end
            task :after_this_execute_thing do
              #
            end
            task :after_this_also_execute_thing do
              #
            end
          end
        end
      end
    end
  end

  if Capistrano::Configuration.instance
    Capistrano::FakeRecipe.load_into(Capistrano::Configuration.instance)
  end
