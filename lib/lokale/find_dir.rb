# Script: Find the current git repository
# Based on https://github.com/mojombo/grit/pull/178 by https://github.com/derricks


module ProjectFinder

  # Returns true if the given path represents a root directory (/ or C:/)
  def root_directory?(file_path)
    # Implementation inspired by http://stackoverflow.com/a/4969416:
    # Does file + ".." resolve to the same directory as file_path?
    File.directory?(file_path) && 
      File.expand_path(file_path) == File.expand_path(File.join(file_path, '..'))
  end

  # Returns the git root directory given a path inside the repo. Returns nil if
  # the path is not in a git repo.
  def find_git_repo(start_path = '.')
    raise NoSuchPathError unless File.exists?(start_path)

    current_path = File.expand_path(start_path)

    # for clarity: set to an explicit nil and then just return whatever
    # the current value of this variable is (nil or otherwise)
    return_path = nil

    until root_directory?(current_path)
      if File.exists?(File.join(current_path, '.git'))   
        # done
        return_path = current_path
        break
      else
        # go up a directory and try again
        current_path = File.dirname(current_path)
      end
    end
    return_path
  end

  ##

  def xcode_project_name(path)
    Dir.glob("#{path}/**/**") { |file| return $1 if file =~ /\/(.+?)\.(?:xcodeproj|xcworkspace)$/ }
  end

  ##

  def find_proj
    project_path = find_git_repo
    if project_path.nil? 
      raise "Could not find any git repository."
    end

    project_name = xcode_project_name(project_path)
    if project_name.nil?
      raise "Found git repository (#{project_path}) does not contain an Xcode project."
    end

    return project_path, project_name
  end
end
