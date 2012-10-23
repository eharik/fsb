desc "This task is called by the Heroku scheduler add-on"
task :scores => :environment do
    puts "Updating Scores..."
    Game.update_scores
    puts "done!"
end

task :games => :environment do
    puts "Updating Games..."
    Game.update_games
    puts "done!"
end

task :matchups => :environment do
    puts "Updating League Matchups..."
    League.update_matchups
    puts "done!"
end
