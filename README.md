# Capistrano SOA 
   - An extension for Capistrano supporting SOA Services Deployment
  
Capistrano SOA let you management services group in SOA architecuture with multi-stage support.

## Usage
  
    project/
      |- config/
          |- deploy.rb
          |- deploy/   
              |- sub_project_a/ 
              |        |- service_a/
              |        |     |- development.rb
              |        |     |- production.rb      
              |        |- service_b
              |              |- development.rb
              |              |- production.rb
              |- sub_project_b/ 
                       |- service_c/
                       |     |- development.rb
                       |     |- production.rb      
                       |- service_d
                             |- development.rb
                             |- production.rb

    cap production sub_project_a:service_a deploy
    
    cap sub_project_a:service_a:production deploy
    
    cap production sub_project_a:service_a sub_project_a:service_b deploy
