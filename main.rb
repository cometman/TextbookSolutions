require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require(:default)


# Definitions
tstate_base = "http://txstate.verbacompare.com/compare/departments/?"
tstate_term = "TERM="

def update_term(term)
  departments = fetch_departments(term)
  if departments.count > 0
    puts "Departments found, trying next term"
    sleep(1)
    next_term = current_term + 1
    update_term(next_term)
  else
    puts "No departments found. Most recent term being recorded as: #{term}"
  end
end

def fetch_departments(term)
  RestClient.get tstate_base + tstate_term + term
end

# Execution
config = YAML.load_file('config.yml')
update_term(config["term"])