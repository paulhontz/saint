class String

  def / path
    '%s/%s' % [self, path]
  end

  def to_md5
    Digest::MD5.hexdigest self
  end
end
