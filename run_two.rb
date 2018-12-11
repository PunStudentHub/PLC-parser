require 'csv'

# run this file after sorting out all the errors with the other one
# 
# day, time, list of classes...
# 

def parse
  timeslots = []
  last_time = 0
  index = -1
  CSV.foreach("output_FINAL.csv", :encoding => 'windows-1251:utf-8') do |row| 
    unless last_time == row[3]
      index += 1
    end

    unless timeslots[index] # create new hash
      timeslots[index] = {day: row[2], time: row[3], classes: []}
    end

    row[4..row.length-1].each do |c|
      if c
        unless timeslots[index][:classes].include?(c)
          timeslots[index][:classes] << c
        end
      end
    end

    
    last_time = row[3]
  end

  p timeslots

  CSV.open("final_final_output.csv", "wb") do |csv|
    timeslots.each do |timeslot|
      csv << [timeslot[:day], timeslot[:time]] + timeslot[:classes]
    end
  end

  CSV.open("stats.csv", "wb") do |csv|
    timeslots.each do |timeslot|
      csv << [timeslot[:day], timeslot[:time], timeslot[:classes].length]
    end
  end
end

parse
