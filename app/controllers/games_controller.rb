class GamesController < ApplicationController
  before_action :set_game, only: %i[ show edit update ]
  helper_method :game_params

  def index
    redirect_to root_path
    # @games = Game.all
  end

  def show
    # @tracks_folder_num = rand(1..4)
    if cookies[:games_played].blank? || cookies[:games_played].to_i <= 1
      @tracks_folder_num = 2
    else
      @tracks_folder_num = rand(1..4)
    end
  end

  def new
    @game = Game.new
    # cookies[:game_id] = nil
  end

  def edit
  end

  def create
    @game = Game.new(game_params)
    cookies[:game_id] = nil
    @game.should_generate_loyalty_hash!

    if @game.save
      # cookies[:game_id] = @game.id
      cookies[:games_played] = cookies[:games_played].present? ? cookies[:games_played].to_i + 1 : 1
      redirect_to game_path(id: 1, game: @game.to_params), notice: "Game was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @game.should_generate_loyalty_hash!
    @game.assign_attributes(game_params)
    if @game.save
      redirect_to @game, notice: "Game was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # def destroy
  #   @game.destroy
  #   redirect_to games_url, notice: "Game was successfully deleted."
  # end

  private
    def set_game
      # @game = Game.find(params[:id] || cookies[:game_id])
      @game = Game.new(game_params)
    end

    def game_params
      params.require(:game).permit(Game.permitted_attributes)
    end
end
