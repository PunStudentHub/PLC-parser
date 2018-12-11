require 'csv'



def parse_schedule
  people = []
  6.times do |day|
    time = 0
    CSV.foreach("tutors.csv", :encoding => 'windows-1251:utf-8') do |row| 
      time += 1 if row[day] =~ /LT:/
      if row[day]
        people << {name: row[day].gsub(/LT:\s*/, '').gsub(/[^0-9a-z ]/i, ''), day: day, time: time-1}
      end
    end
  end

  #CSV.open("neat_tutors.csv", "wb") do |csv|
  #  new_file.each do |tutor|
  #    csv << tutor
  #  end
  #end
  people
end

def parse_classes
  people = []
  
  CSV.foreach("classes.csv", :encoding => 'windows-1251:utf-8') do |row|
    person = {name: row[0].gsub(/[^0-9a-z ]/i, ''), classes: []}
    row.each do |cell|
      unless cell == row[0]
        unless cell =~ /I do not/
          unless %w{Yes No}.include? cell
            person[:classes] += cell.split(', ')
          else
            person[:classes] << "Writing"
          end
        end
      end
    end
    people << person
  end
  people

  CSV.open("parsed_classes.csv", "wb") do |csv|
    people.each do |tutor|
      csv << [tutor[:name]] + tutor[:classes]
    end
  end
end



@people_classes = parse_classes
@people_times = parse_schedule

def merge
  file = []
  conflicts = []; failures = [];
  @people_times.each do |person_time|
    possible_people = @people_classes.select { |p| p[:name].split(' ')[0].downcase == person_time[:name].split(' ')[0].downcase }
    if possible_people.length > 1
      same_last_name = possible_people.select { |p| p[:name].split(' ')[1].downcase == person_time[:name].split(' ')[1].downcase }
      if same_last_name.length > 0
        file << [person_time[:name], same_last_name[0][:name], person_time[:day], person_time[:time]] + possible_people[0][:classes]
      elsif same_last_name.length > 1
        failures << person_time
      else
        same_last_initial = possible_people.select { |p| p[:name].split(' ')[1].split('')[0..1] == person_time[:name].split(' ')[1].split('')[0..1] }
        if same_last_initial.length > 0 && same_last_initial.length < 2
          file << [person_time[:name], same_last_initial[0][:name], person_time[:day], person_time[:time]] + same_last_initial[0][:classes]
        else
          conflicts << person_time
          file << [person_time[:name], '', person_time[:day], person_time[:time]]
        end
      end
    elsif possible_people.length < 1 
      failures << person_time
      file << [person_time[:name], '', person_time[:day], person_time[:time]]
    else
      file << [person_time[:name], possible_people[0][:name], person_time[:day], person_time[:time]]  + possible_people[0][:classes]
    end

  end
  print_errors "Failures", failures
  print_errors "Conflicts", conflicts

  CSV.open("output.csv", "wb") do |csv|
    file.each do |tutor|
      csv << tutor
    end
  end
end

def print_errors name, array
  puts "=== #{name.upcase}: #{array.length} ==="
  array.sort! {|a, b| a[:name] <=> b[:name]}
  array.each do |a|
    puts a[:name]
  end
end


merge
