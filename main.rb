require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require(:default)


# Definitions
@tstate_base = "http://txstate.verbacompare.com/compare"
@config = YAML.load_file('config.yml')

# Retrieve departments for the given term.  Retry 3 times if there is a failure. Abort script after 3rd.
def fetch_departments(term)
  begin
    retries ||= 0
    JSON.parse(RestClient.get "#{@tstate_base}/departments", {:params => { :term => term}})
  rescue => e
    puts "Fetch department critical error! #{e.message}....Retrying..."
    sleep(5)
    retry if (retries += 1) < 3
    abort
  end
end

# Fetch courses for particular department.  Retry 3 times if there is a failure. Abort script after 3rd.
def fetch_courses(department)
  begin
    retries ||= 0
    JSON.parse(RestClient.get "#{@tstate_base}/courses", {:params => { :id => department, :term_id => @config["term"]}})
  rescue => e
    puts "Fetch course critical error! #{e.message}....Retrying..."
    sleep(5)
    retry if (retries += 1) < 3
    abort
  end  
end

# Fetch sections for particular course.  Retry 3 times if there is a failure. Abort script after 3rd.
def fetch_sections(course)
  begin
    retries ||= 0
    JSON.parse(RestClient.get "#{@tstate_base}/sections", {:params => { :id => course, :term_id => @config["term"]}})
  rescue => e
    puts "Fetch section critical error! #{e.message}....Retrying..."
    sleep(5)
    retry if (retries += 1) < 3
    abort
  end  
end

# Fetch material for given section.  Retry 3 times if there is a failure.  Abort script after 3rd.
def fetch_material_information(section)
  begin
    retries ||= 0
    JSON.parse(RestClient.get "#{@tstate_base}/books", {:params => { :id => section}})
  rescue => e
    puts "Fetch section materials critical error! #{e.message}....Retrying..."
    sleep(5)
    retry if (retries += 1) < 3
    abort
  end  
end

# Update config file with latest available departments. Return most recent departments
def update_term_return_department(term)
  departments = fetch_departments(term)
  if departments.count > 0
    puts "Departments found, trying next term"
    sleep(1)
    next_term = term + 1
    update_term_return_department(next_term)
  else
    @config["term"] = term - 1
    puts "No departments found. Most recent term being recorded as: #{@config["term"]}"
    # Write config to file
    File.open('config.yml','w') do |h| 
      h.write @config.to_yaml
    end
  end
  return departments
end

# Execution
all_departments = update_term_return_department(@config["term"])
puts "Departments found - #{all_departments.count}"
return_hash = {}
# Add departments
all_departments.each do |department|
  return_hash[department["name"]] = {}
  all_courses = fetch_courses(department["id"])
  puts "Courses found in department [#{department["name"]}] - #{all_courses.count}"

  # Add courses to each department
  all_courses.each do |course|
    return_hash[department["name"]][course["name"]] = {}
    all_sections = fetch_sections(course["id"])

    # Add sections to each course
    all_sections.each do |section|
      return_hash[department["name"]][course["name"]][section["name"]] = {"instructor" => section["instructor"]}
      all_material = fetch_material_information(section["id"])

      # Add material to each course
      return_hash[department["name"]][course["name"]][section["name"]]["material"] = []
      all_material.each do |material|

        # Determine if book is required
        case material["required"].downcase
        when "recommended"
          required = "RC"
        when "required"
          required = "RQ"
        when "optional"
          required = "OP"
        else
          required = ""
        end

        # Save all data to hash
        return_hash[department["name"]][course["name"]][section["name"]]["material"].push(
          {
            "isbn" => material["isbn"],
            "no_book_required" => material["citation"].downcase().include?("no text required") ? "Y" : "N",
            "enrollement" => nil,
            "paper_adoption" => "N",
            "required" => required
          }
        )
        byebug
      end
    end
  end
end
byebug
puts return_hash

