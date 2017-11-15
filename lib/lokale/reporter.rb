module Lokale
  class Reporter
    def initialize(agent)
      @agent = agent
    end

    def print_summary
      print_macro_calls_summary
      print_macro_table
      print_files_table
      print_repeats_report
      print_diferences_report
    end 

    def print_macro_calls_summary
      total_macro_calls = @agent.macros.map(&:total_count).reduce(:+)
      uniq_macro_calls = @agent.macros.map(&:uniq_count).reduce(:+)
      puts "Found #{total_macro_calls} localization macro calls in #{@agent.sfiles_proceeded} files."
      puts "Uniq macro calls: #{uniq_macro_calls}"
      puts
    end

    def print_files_table
      languages = @agent.lfiles.map { |e| e.lang }.to_set.to_a
      files = @agent.lfiles.map { |e| e.full_name }.to_set.to_a

      puts "Found #{@agent.lfiles.size} localized files for #{languages.size} languages."

      description_header = "[*]".rpadded(36)
      languages.each { |l| description_header << l.rpadded(8) }
      puts description_header

      files.each do |f|
        description_string = f.rpadded(36)
        languages.each do |l|
          lfile = @agent.lfiles.select { |lf| lf.full_name == f && lf.lang == l }
          description_string << (lfile.empty? ? "-" : lfile[0].parsed.nil? ? "*" : "#{lfile[0].parsed.size}").rpadded(8)
        end
        puts description_string
      end
      puts
    end

    def print_macro_table
      @agent.macros.each do |macro|
        puts "#{macro.name}:".rpadded(24) + "total: #{macro.total_count}".rpadded(16) + "uniq: #{macro.uniq_count}"
      end
      puts
    end

    def print_repeats_report
      repeats_repot = ""
      @agent.lfiles.each do |lf| 
        repeats = lf.repeats
        next if repeats.count.zero?
        repeats_repot << "#{lf.lang}/#{lf.full_name} repeats:\n"
        repeats_repot << repeats.join("\n")
        repeats_repot << "\n"
      end

      if repeats_repot.empty? 
        puts "Repeats not found.".green
        puts
      else
        puts "Found repeats in strings files.".red
        puts repeats_repot
        puts
      end
    end

    def print_diferences_report
      diferences_repot = ""

      @agent.lfiles.group_by { |f| f.full_name }.each do |file_name, files|
        base_lang = files.any? { |f| f.lang == "Base" } ? "Base" : "en"
        files = files.select { |f| f.lang != base_lang }
        all_keys = files.map(&:keys).compact.map(&:to_set)
        next if all_keys.empty?
        united_keys = all_keys.reduce(:|)
        all_keys.map! { |ks| united_keys - ks }
        next if all_keys.map(&:length).reduce(:+).zero?

        diferences_repot << "Missing keys in file \"#{file_name}\":\n"
        all_keys.zip(files) do |missing_keys, lfile|
          next if missing_keys.size.zero?
          diferences_repot << "*".red + " #{lfile.lang} - #{missing_keys.size} key(s):\n"
          missing_keys.each { |k| diferences_repot << "#{k}\n" }
        end
        diferences_repot << "\n"
      end

      if diferences_repot.empty? 
        puts "Localization files are full.".green
        puts
      else
        puts "Localization files are not full.".red
        puts diferences_repot
        puts
      end
    end 
  end
end