
class ::Hash
  def to_string
    return self.to_a.collect{|x| x[0].to_s+"="+x[1].to_s.squish}.join("\r\n")
  end
end


class ::String
  def to_hash
    h = {}
    self.split("\r\n").collect{|x| h.store(x.split("=")[0].to_sym, x.match(/^[a-z\_]*=(.*)/).to_a[1])}
    return h
  end
end
