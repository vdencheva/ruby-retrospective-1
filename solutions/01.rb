class Array
  def to_hash
    inject({}) do |result_hash, item|
      result_hash[item[0]] = item[1]
      result_hash
    end
  end
  
  def index_by
    map { |item| [yield(item), item] }.to_hash
  end
  
  def subarray_count(subarray)
    each_cons(subarray.length).count(subarray)
  end
  
  def occurences_count
    Hash.new(0).tap do |result_hash|
      each { |item| result_hash[item] += 1 }
    end
  end
end
