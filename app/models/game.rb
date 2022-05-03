class Game < ApplicationRecord
  DEFAULT_METHOD = :unique_first_and_last
  DEFAULT_SLACK = 0.0
  SHUFFLE_METHODS = %i[
    unique_first
    unique_first_and_last
    empires_balance
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
    method_sym = self.shuffle_method.to_sym || DEFAULT_METHOD
    # overriding slack: 2p -> 2, 3p -> 1, 4p -> 0
    self.empires_balance_slack = 4 - players_count if method_sym == :empires_balance

    self.player_loyalties_hash = generate_loyalty_hash(method: method_sym)
    self.should_generate_loyalty_hash = false
    save!
  end

  def self.permitted_attributes
    %i[player_loyalties_hash player_end_ranking shuffle_method empires_balance_slack] + [{player_to_factions_array: []}]
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

  def generate_loyalty_hash(method: DEFAULT_METHOD, slack: DEFAULT_SLACK)
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
    when :empires_balance
      generate_empire_balance(slack: empires_balance_slack)
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

  def generate_empire_balance(slack: DEFAULT_SLACK)
    @p1_int = (0..4).to_a
    @vals_to_int = (0..4).to_a.reverse.map{|x| 10**x }
    @score_multipliers = WarOfWhispers.loyalty_names.values.map{|o| o[:multiplier] }
    mean_score = @score_multipliers.sum(0.0) / @score_multipliers.length
    mean_score_by_playercount = mean_score * players_count
    @max_empire_score = (mean_score_by_playercount + slack.to_f / 2).ceil
    @min_empire_score = (mean_score_by_playercount - slack.to_f / 2).floor

    possible_setups = [[]] # initialize with possible setups for 1 player (only 1 possibility)
    for p_index in 2..players_count do
      # for each subsequent player, add all permutations to all existing setups (ignoring invalid setups that are produced)
      possible_setups = possible_setups.flat_map do |n_minus_one_setup|
        @p1_int.permutation(5).to_a.filter_map{|player_n| n_minus_one_setup + [player_n] if is_monotonous_setup?(n_minus_one_setup.last, player_n) && is_balanced_setup?(n_minus_one_setup + [player_n]) }
      end
    end

    (possible_setups.sample + [@p1_int]).shuffle.each_with_index{|setup, i| @temp_loyalty_hash[i + 1] = setup }
    @temp_loyalty_hash
  end

  def is_balanced_setup?(setup)
    setup_players_missing = players_count - (setup.size + 1)
    empires_score_array = calc_empires_score(setup)

    return empires_score_array.values.all? do |value|
      (value + @score_multipliers.min * setup_players_missing <= @max_empire_score) && (value + @score_multipliers.max * setup_players_missing >= @min_empire_score)
    end
  end

  def calc_empires_score(setup)
    ([@p1_int] + setup).inject({0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0}) do |h, player|
      player.each_with_index do |empire, loyalty_index|
        h[empire] += @score_multipliers[loyalty_index]
      end
      h
    end
  end

  def is_monotonous_setup?(n_minus_one_setup, nth_setup)
    setup_to_int(n_minus_one_setup) <= setup_to_int(nth_setup)
  end

  def setup_to_int(setup)
    setup.nil? ? 0 : setup.join.to_i
  end
end


