# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

    #Game.update_games
    #Game.update_scores
    #@league.update_bets
    
    
every 1.hour do
  runner "Game.update_scores"
end

every 12.hours do
  runner "Game.update_games"  
end

every 1.day, :at => "2:00 am" do
  runner "League.update_bets"
end
