require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.gsub(/[^0-9]/, '')
  if phone_number.length < 10
    phone_number = "0000000000"
    return phone_number
  elsif phone_number.length == 10
    return phone_number
  elsif phone_number.length == 11
    if phone_number[0] == 1
      phone_number.slice!(0)
      return phone_number
    elsif
      phone_number = "0000000000"
      return phone_number
    end
  elsif phone_number.length > 11
    phone_number = "0000000000"
    return phone_number
  end
end

def get_date(regDate)
  format = "%m/%d/%y"
  date = Date.strptime(regDate, format)
end

def get_time(regDate)
  time_only = regDate.split(' ')
  time = time_only[1]
  return time
end

def round_to_nearest_hour(time)
  hours, minutes = time_str.split(':').map(&:to_i)

  if minutes >= 30
    hours += 1
  end

  hours %= 24 # Handle 24 hour wraparound

  return format("%02d:00", hours)
end

def time_average(time_array)
  total_minutes = time_array.reduce(0) do |sum, time_str|
    hours, minutes = time_str.split(':').map(&:to_i)
    sum + (hours * 60 + minutes)
  end
  average_minutes = total_minutes / time_array.length
  average_hours = average_minutes / 60
  average_minutes %= 60
  return format("%02d:%02d", average_hours, average_minutes)
end

def date_average(date_array)
  day_sum = 0
  date_array.each do |element|
    day_sum += element.wday
  end

  average_day = day_sum / date_array.length
  days = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
  return days[average_day]

end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end



puts 'EventManager initialized.'

contents = CSV.open(
  'lib/event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('lib/form_letter.erb')
erb_template = ERB.new template_letter
time_array = []
date_array = []

contents.each do |row|

  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  #phone_number = row[:homephone] #debug
  #puts "#{name} #{phone_number}" #debug
  date = get_date(row[:regdate])
  time = get_time(row[:regdate])
  time_array << time
  date_array << date
  puts "#{name} date: #{date} time: #{time}"
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "The average time of regisration is #{time_average(time_array)}"
puts "The average day of regisration is #{date_average(date_array)}"