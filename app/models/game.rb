class Game < ApplicationRecord
  DEFAULT_METHOD = :unique_first_and_last
  SHUFFLE_METHODS = %i[
    unique_first
    unique_first_and_last
    teams
    cyclical
    completely_random
    at_least_2_unique
    at_least_3_unique
    at_least_4_unique
  ]

  # validates :players_count, presence: true, numericality: {integer_only: true, greater_than_or_equal_to: 2, less_than_or_equal_to: 4 }
  validate :validate_players_count

  before_validation :remove_nil_from_player_to_factions_array, if: :player_to_factions_array_changed?
  after_save :save_loyalty_hash, if: :should_generate_loyalty_hash

  attr_accessor :should_generate_loyalty_hash

  def save_loyalty_hash
    self.player_loyalties_hash = generate_loyalty_hash(method: self.shuffle_method.to_sym || DEFAULT_METHOD)
    self.should_generate_loyalty_hash = false
    save!
  end

  def self.permitted_attributes
    %i[player_loyalties_hash player_end_ranking shuffle_method] + [{player_to_factions_array: []}]
  end

  def should_generate_loyalty_hash!
    self.should_generate_loyalty_hash = true
  end

  def players_count
    @players_count ||= player_to_factions_array.compact.size
  end

  def players_indexes
    (1..self.players_count).to_a
  end

  private

  def validate_players_count
    errors[:"player_selection:"] << "Cannot have more than 4 players" if players_count > 4
    errors[:"player_selection:"] << "Must have at least 2 players" if players_count < 2
    errors[:"player_selection:"] << "Must have at least 3 players for this mode" if players_count < 3 && shuffle_method == 'cyclic'
    errors[:"player_selection:"] << "Must have at least 4 players for this mode" if players_count < 4 && shuffle_method == 'teams'
  end

  def remove_nil_from_player_to_factions_array
    self.player_to_factions_array = player_to_factions_array.compact
  end

  def generate_loyalty_hash(method: DEFAULT_METHOD)
    # generate empty loyalty arrays for each player
    @temp_loyalty_hash = players_indexes.each_with_object({}) do |k, h|
      h[k] = Array.new(5)
    end

    case method
    when :unique_first
      populate_places_uniquely(places: [0])
      populate_rest
    when :unique_first_and_last
      populate_places_uniquely(places: [0,-1])
      populate_rest
    when :teams
      raise 'Must be played with 4 players' if self.players_count != 4
      seed = WarOfWhispers.loyalty_map.keys.shuffle
      seed_partner = [seed[1], seed[0], seed[2], seed[4], seed[3]]
      shuffleed_players = players_indexes.shuffle
      @temp_loyalty_hash[shuffleed_players[0]] = seed
      @temp_loyalty_hash[shuffleed_players[1]] = seed_partner
      @temp_loyalty_hash[shuffleed_players[2]] = seed.reverse
      @temp_loyalty_hash[shuffleed_players[3]] = seed_partner.reverse
    when :cyclical
      raise 'Cannot be played with 2 players' if self.players_count == 2
      seed = WarOfWhispers.loyalty_map.keys.shuffle
      shuffleed_players = players_indexes.shuffle

      @temp_loyalty_hash[shuffleed_players[0]] = seed

      case self.players_count
      when 3
      # @temp_loyalty_hash[shuffleed_players[0]] = [seed[0], seed[1], seed[2], seed[3], seed[4]]
        @temp_loyalty_hash[shuffleed_players[1]] = [seed[2], seed[1], seed[4], seed[3], seed[0]]
        @temp_loyalty_hash[shuffleed_players[2]] = [seed[4], seed[1], seed[0], seed[3], seed[2]]
      when 4
      # @temp_loyalty_hash[shuffleed_players[0]] = [seed[0], seed[1], seed[2], seed[3], seed[4]]
        @temp_loyalty_hash[shuffleed_players[1]] = [seed[1], seed[3], seed[2], seed[4], seed[0]]
        @temp_loyalty_hash[shuffleed_players[2]] = [seed[3], seed[4], seed[2], seed[0], seed[1]]
        @temp_loyalty_hash[shuffleed_players[3]] = [seed[4], seed[0], seed[2], seed[1], seed[3]]
      end
    when :completely_random
      shuffle_until_unique(minimum_unique_positions: 1)
    when :at_least_2_unique
      shuffle_until_unique(minimum_unique_positions: 2)
    when :at_least_3_unique
      shuffle_until_unique(minimum_unique_positions: 3)
    when :at_least_4_unique
      shuffle_until_unique(minimum_unique_positions: 4)
    end

    @temp_loyalty_hash
  end

  def shuffle_until_unique(minimum_unique_positions: 1)
    players_indexes.each do |i|
      loop do
        @temp_loyalty_hash[i] = WarOfWhispers.loyalty_map.keys.shuffle
        break if calc_minimum_unique_positions(@temp_loyalty_hash.values[0..i]) >= minimum_unique_positions
      end
    end
  end

  def calc_minimum_unique_positions(arrays)
    min = arrays[0].length
    return min if arrays.length == 1

    arrays.combination(2).each do |pair|
      uniques = pair[0].zip(pair[1]).sum{|a| a[0] == a[1] ? 0 : 1 }
      min = [min, uniques].min
    end
    min
  end

  def populate_places_uniquely(places: )
    # populate given places with unique values
    places.each do |pos|
      @temp_loyalty_hash.keys.each do |k|
        taken = @temp_loyalty_hash[k].compact | @temp_loyalty_hash.values.map{|h| h[pos] }
        @temp_loyalty_hash[k][pos] = (WarOfWhispers.loyalty_map.keys - taken).sample
      end
    end
  end

  def populate_rest
    # populate the rest of the loyalty arrays with random values
    @temp_loyalty_hash.each do |k, array|
      array.each_with_index do |v,i|
        @temp_loyalty_hash[k][i] = (WarOfWhispers.loyalty_map.keys - @temp_loyalty_hash[k].compact).sample if v.nil?
      end
    end
  end
end


