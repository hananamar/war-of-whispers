class GamesController < ApplicationController
  before_action :set_game, only: %i[ show edit update destroy ]

  def index
    @games = Game.all
  end

  def show
  end

  def new
    @game = Game.new
    cookies[:game_id] = nil
  end

  def edit
  end

  def create
    @game = Game.new(game_params)
    cookies[:game_id] = nil
    @game.should_generate_loyalty_hash!

    if @game.save
      cookies[:game_id] = @game.id
      redirect_to @game, notice: "Game was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @game.should_generate_loyalty_hash!
    if @game.update(game_params)
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
      @game = Game.find(params[:id] || cookies[:game_id])
    end

    def game_params
      params.require(:game).permit(Game.permitted_attributes)
    end
end
