class Song
  attr_accessor :name, :artist, :genre, :subgenre, :tags
  def initialize(name, artist, genre, subgenre, tags, artist_tags)
    @name, @artist = name, artist
    @genre, @subgenre, @tags = genre, subgenre, tags
    add_tags_for_artist(artist_tags)
    add_tags_for_genre()
  end
  
  def add_tags_for_artist(artist_tags)
    @tags += artist_tags[@artist] if artist_tags[@artist]
  end
  
  def add_tags_for_genre()
    @tags.push(@genre.downcase) if @genre
    @tags.push(@subgenre.downcase) if @subgenre
  end
 
  def matches?(criteria)
    if (criteria[:tags] && not(matches_tags? criteria[:tags])) || 
      (criteria[:name] && not(matches_name? criteria[:name])) || 
      (criteria[:artist] && not(matches_artist? criteria[:artist])) || 
      (criteria[:filter] && not(matches_filter? &criteria[:filter]))
      false
    else
      true
    end
  end
  
  def matches_tags?(tags)
    Array(tags).all? do |tag|
      tag.end_with?('!') ^ @tags.include?(tag.chomp('!'))
    end
  end
  
  def matches_name? (name)
    @name == name
  end
  
  def matches_artist? (artist)
    @artist == artist
  end
  
  def matches_filter? (&block)
    block.call(self)
  end
end

class Collection
  def initialize(songs_as_string, artist_tags)
    @songs_collection = songs_as_string.lines.map do |line|
      create_song(line, artist_tags)
    end
  end
  
  def create_song(string_to_parse, artist_tags)
    parsed_array = string_to_parse.split('.').map(&:strip)
    name, artist = parsed_array[0], parsed_array[1]
    genre, subgenre = parsed_array[2].split(',').map(&:strip)
    tags = parsed_array[3] ? parsed_array[3].split(',').map(&:strip) : [] 
    Song.new(name, artist, genre, subgenre, tags, artist_tags)
  end
  
  def find(criteria)
    @songs_collection.select { |song| song.matches? criteria }
  end
end