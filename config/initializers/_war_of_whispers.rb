module WarOfWhispers
  def self.loyalty_map
    {
      0 => {name: 'The Bear Empire', color: 'blue', image: 'bear.png'},
      1 => {name: 'The Eagle Empire', color: 'red', image: 'eagle.png'},
      2 => {name: 'The Elephant Empire', color: 'green', image: 'elephant.png'},
      3 => {name: 'The Lion Empire', color: 'yellow', image: 'lion.png'},
      4 => {name: 'The Horse Empire', color: 'brown', image: 'horse.png'},
    }
  end

  def self.loyalty_names
    {
      0 => {name: 'Devout', image: ''},
      1 => {name: 'Dutiful', image: ''},
      2 => {name: 'Affiliated', image: ''},
      3 => {name: 'Unallied', image: ''},
      4 => {name: 'Opposed', image: ''},
    }
  end

  def self.players_map
    {
      0 => {name: 'The Pale Raven', color: 'white', image: 'raven.jpg', mp3: 'pale_raven.mp3'},
      1 => {name: 'Cult of the Rat', color: 'orange', image: 'rat.jpg', mp3: 'cult_of_the_rat.mp3'},
      2 => {name: 'The Supplicant Spider', color: 'black', image: 'spider.jpg', mp3: 'supplicant_spider.mp3'},
      3 => {name: 'The Endless Serpent', color: 'purple', image: 'serpent.jpg', mp3: 'endless_serpent.mp3'},
    }
  end
end