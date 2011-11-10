class Array
  def to_hash
    inject({}) do |result_hash, item|
      result_hash[item[0]] = item[1]
      result_hash
    end
  end
  
  def index_by
    inject({}) do |result_hash, item|
      result_hash[yield item] = item
      result_hash
    end
  end
  
  def subarray_count(subarray)
    count = 0
    each_cons(subarray.length) do |array_cons|
      count += 1 if (array_cons == subarray)
    end
    count
  end
  
  def occurences_count
    inject(Hash.new(0)) do |result_hash, item|
      result_hash[item] += 1
      result_hash
     end
  end
end