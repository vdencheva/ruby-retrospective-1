class Song
  attr_accessor :name, :artist, :genre, :subgenre, :tags
  def initialize(args, artist_tags)
    @name, @artist = args[0], args[1]
    @genre, @subgenre = args[2].split(',').map(&:strip)
    @tags = args[3] ? args[3].split(',').map(&:strip) : [] 
    tags_by_artist(artist_tags)
    tags_by_genre()
  end
  
  def tags_by_artist(artist_tags)
    @tags += artist_tags[@artist] if artist_tags[@artist]
  end
  
  def tags_by_genre()
    @tags.push(@genre.downcase) if @genre
    @tags.push(@subgenre.downcase) if @subgenre
  end
  
  def matches_tags?(tags)
    Array(tags).each do |tag|
      if tag.end_with?('!')
        return false if @tags.include? tag.chop
      else
        return false unless @tags.include? tag
      end
    end
    true
  end
  
  def matches_name? (name)
    @name == name ? true : false
  end
  
  def matches_artist? (artist)
    @artist == artist ? true : false
  end
  
  def matches_filter? (&block)
    block.(self)
  end
end

class Collection
  def initialize(songs_as_string, artist_tags)
    @songs_collection = songs_as_string.lines.map do |line|
      Song.new(line.split('.').map(&:strip), artist_tags)
    end
  end
  
  def find(criteria)
    result = @songs_collection.dup
    if criteria[:tags]
      result = result.select { |song| song.matches_tags? criteria[:tags] }
    end
    if criteria[:name]
      result = result.select { |song| song.matches_name? criteria[:name] }
    end
    if criteria[:artist]
      result = result.select { |song| song.matches_artist? criteria[:artist] }
    end
    if criteria[:filter]
      result = result.select { |song| song.matches_filter? &criteria[:filter] }
    end
    result
  end
end