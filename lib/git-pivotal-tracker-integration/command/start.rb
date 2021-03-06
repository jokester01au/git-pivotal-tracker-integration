# Git Pivotal Tracker Integration
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'git-pivotal-tracker-integration/command/base'
require 'git-pivotal-tracker-integration/command/command'
require 'git-pivotal-tracker-integration/util/git'
require 'git-pivotal-tracker-integration/util/story'
require 'pivotal-tracker'

# The class that encapsulates starting a Pivotal Tracker Story
class GitPivotalTrackerIntegration::Command::Start < GitPivotalTrackerIntegration::Command::Base

  # Starts a Pivotal Tracker story by doing the following steps:
  # * Create a branch
  # * Add default commit hook
  # * Start the story on Pivotal Tracker
  #
  # @param [String, nil] filter a filter for selecting the story to start.  This
  #   filter can be either:
  #   * a story id
  #   * a story type (feature, bug, chore)
  #   * +nil+
  # @return [void]
  def run(filter = nil, limit = 10)
    if filter == '-h' or filter == '--help'
      help
      return
    end

    puts 'Type `git start -h` for help'
    story = GitPivotalTrackerIntegration::Util::Story.select_story @project, filter, limit

    GitPivotalTrackerIntegration::Util::Story.pretty_print story

    development_branch_name = development_branch_name story
    if not development_branch_name.nil?
        GitPivotalTrackerIntegration::Util::Git.create_branch development_branch_name
    end    
    @configuration.story = story

    GitPivotalTrackerIntegration::Util::Git.add_hook 'prepare-commit-msg', File.join(File.dirname(__FILE__), 'prepare-commit-msg.sh')

    start_on_tracker story
  end

  private

  def development_branch_name(story)
    branch_name = "#{story.id}-" + ask("Enter branch name (#{story.id}-<branch-name> or enter to skip branch creation): ")
    puts
    branch_name
  end

  def start_on_tracker(story)
    print 'Starting story on Pivotal Tracker... '
    story.update(
      :current_state => 'started',
      :owned_by => GitPivotalTrackerIntegration::Util::Git.get_config('user.name')
    )
    puts 'OK'
  end

  def help
    puts 'USAGE: git start [id|type|filter[\'|\'filter ...]] [limit]'
    puts
    puts '       id:      the id of a pivotal tracker story'
    puts '       type:    bug|feature|chore'
    puts '       filter:  a string of the form key:value. See https://www.pivotaltracker.com/help/faq#howcanasearchberefined for examples'
    puts
    puts '                Some useful examples:     \'label:add-ons\', \'created_since:6/20/2015\', \'mywork:josephtk\', \'owner:josephtk\', \'requester:josephtk\', \'no:owner\''
    puts
    puts '       limit:   the maximum number of items to return (default 10)'
  end  

end
