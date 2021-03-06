require "quality_meter/version"
# require 'quality_meter/railtie' if defined?(Rails)
require "csv"
require "quality_meter/engine"

module QualityMeter
  def initialize_thresholds(thresholds)
    # Initialize threshold values
    @security_warnings_min = thresholds['security_warnings_min']
    @security_warnings_max = thresholds['security_warnings_max']

    @rails_best_practices_min = thresholds['rails_best_practices_min']
    @rails_best_practices_max = thresholds['rails_best_practices_max']

    @flog_complexity_min = thresholds['flog_complexity_min']
    @flog_complexity_max = thresholds['flog_complexity_max']

    @stats_ratio_min = thresholds['stats_ratio_min']
    @stats_ratio_max = thresholds['stats_ratio_max']

    @app_data = []
  end

  def collect_brakeman_details
    # Breakman source file
    file = check_and_assign_file_path('report.json')
    if file
      data_hash = JSON.parse(file)
      ### change array to hash and check it contain warnings or not
      if data_hash.present? && data_hash.class == Hash ? data_hash.has_key?('warnings') : data_hash[0].has_key?('warnings')
        warning_type = data_hash['warnings'].map {|a| a = a['warning_type'] }
        assign_warnings(warning_type, data_hash['warnings'].count)
      elsif data_hash[0].has_key?('warning_type')
        assign_warnings([data_hash[0]['warning_type']])
      end
    end
  end

  def collect_app_data
    @app_data = {app_path: "/home/arpit/applications/G8way/g8way",rails_version: "3.2.11",security_warnings: 84}
    # Breakman source file
    file = check_and_assign_file_path('report.json')
    if file
      data_hash = JSON.parse(file)
    # change array to hash and check it contain warnings or not
      if data_hash.present? && data_hash.has_key?('scan_info')
        @app_data =   {application: data_hash['scan_info']['app_path'].split("/").last, ruby_version: data_hash['scan_info']['ruby_version'], rails_version: data_hash['scan_info']['rails_version'], number_of_models: data_hash['scan_info']['number_of_models'], number_of_controllers: data_hash['scan_info']['number_of_controllers'], number_of_templates:  data_hash['scan_info']['number_of_templates']}
      end
    end
  end

  ### Assign warnings to @breakeman_warnings ###
  def assign_warnings(warning_type, warnings_count=1)
    @brakeman_warnings = Hash.new(0)
    # warning_type = data_hash[0]['warning_type']
    @warnings_count = warnings_count
    warning_type.each do |v|
      @brakeman_warnings[v] += 1
    end
  end

  def collect_metric_fu_details
  # parsing metric_fu report from .yml file
    file = check_and_assign_file_path('tmp/metric_fu/report.yml')
    if file
      @surveys  = YAML.load(ERB.new(file).result)
      @surveys.each do |survey|
        assign_status(survey) if survey.present?
      end
    end
  end

  ### assing ration ,complexity and bestpractice of code ###
  def assign_status(survey)
    case survey[0]
      when :flog
        @flog_average_complexity = survey[1][:average].round(1)
      when :stats
        @stats_code_to_test_ratio = survey[1][:code_to_test_ratio]
      when :rails_best_practices
        @rails_best_practices_total = survey[1][:total].first.gsub(/[^\d]/, '').to_i
    end
  end

  def generate_final_report
    collect_app_data
    collect_metric_fu_details
    collect_brakeman_details
    @app_root = Rails.root
    get_previour_result
  end

  def save_report
    # Save report data into the CSV
    ### Hide this because we are not using this currently
    #flag = false
    #flag = File.file?("#{Rails.root}/quality_meter.csv")
    CSV.open("#{Rails.root}/quality_meter.csv", "a") do |csv|
      #csv << ['flog','stats','rails_best_practices','warnings', 'timestamp'] if flag == false
      sha = `git rev-parse HEAD`
      csv << [@flog_average_complexity, @stats_code_to_test_ratio, @rails_best_practices_total, @warnings_count, sha]
    end
  end

  def get_previour_result
    # Get previous report data
    @previous_reports = CSV.read("#{Rails.root}/quality_meter.csv").last(4) if File.file?("#{Rails.root}/quality_meter.csv")
  end

  def choose_color
    # Check threashhold
    ### set color to the variables ###
    @brakeman_warnings_rgy = set_color(@warnings_count, @security_warnings_max,  @security_warnings_min)
    @rails_best_practices_rgy = set_color(@rails_best_practices_total, @rails_best_practices_max, @rails_best_practices_min)
    @flog_rgy = set_color(@flog_average_complexity, @flog_complexity_max, @flog_complexity_min)
    @stats_rgy = set_stat_color(@stats_code_to_test_ratio, @stats_ratio_max, @stats_ratio_min )
  end

  ### method to check file is exist or not ###
  def check_and_assign_file_path(path)
    file = "#{Rails.root}/#{path}"
    File.exist?(file) ? File.read(path)  : nil
  end

  ### send proper color according to data ###
  def set_color(count, max, min)
    if count.present? && count > max
      'background-color:#D00000;'
    elsif count.present? && count > min && count < max
      avg  = max.to_f / 2.to_f
      low_avg = avg / 2.to_f
      high_avg = avg + low_avg
      if count >= high_avg 
        'background-color:#D00000;'
      elsif count >= avg && count < high_avg 
        'background-color:orange;'
      elsif count <= low_avg
        'background-color:green;'
      elsif count >= low_avg
        'background-color:yellow;'
      else
        'background-color:#D00000;'
      end
    else
      'background-color:#006633;'
    end
  end

  ### @arpit: send proper color according to data ###
  def set_stat_color(count, max, min)
    if count.present? && count > max
      'background-color:#D00000;'
    elsif count.present? && count > min && count < max
      avg  = max.to_f / 2.to_f
      low_avg = avg / 2.to_f
      if count > avg 
        'background-color:green;'
      elsif count < avg && count < low_avg
        'background-color:#D00000;'
      elsif count < avg && count > low_avg
        'background-color:orange;'
      else
        'background-color:#D00000;'
      end
    else
      'background-color:#006633;'
    end

  end
end
