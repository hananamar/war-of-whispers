class PagesController < ApplicationController

  def home
    @games_count = Game.all.count
  end

  def help
    
  end

end
