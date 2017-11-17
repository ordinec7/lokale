class String
  def rpadded(count=20)
    "%-#{count}.#{count}s" % self
  end

  def lpadded(count=20)
    "%#{count}.#{count}s" % self
  end
end

module Then
	def then		
		yield self
		return self
	end
end