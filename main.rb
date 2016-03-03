require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require(:default)


# Definitions
@tstate_base = "http://txstate.verbacompare.com/compare/departments/"
@config = YAML.load_file('config.yml')

def fetch_departments(term)
  RestClient.get @tstate_base, {:params => { :term => term}}
end

def fetch_courses(department)
  RestClient.get @tstate_base, {:params => { :id => department, :term => @config["term"]}}
end

def update_term(term)
  departments_raw = fetch_departments(term)
  begin
    retries ||= 0
    departments = JSON.parse(departments_raw)
  rescue => e
    puts "CRITICAL ERROR! #{e.message}....Retrying..."
    retry if (retries += 1) < 3
    abort
  end
  if departments.count > 0
    puts "Departments found, trying next term"
    sleep(1)
    next_term = term + 1
    update_term(next_term)
  else
    @config["term"] = term - 1
    puts "No departments found. Most recent term being recorded as: #{@config["term"]}"
    # Write config to file
    File.open('config.yml','w') do |h| 
      h.write @config.to_yaml
    end
  end
end

# Execution
update_term(@config["term"])
#departments = fetch_departments(config["term"])