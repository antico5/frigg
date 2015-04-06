class Blog < ActiveRecord::Base
  belongs_to :user
  has_many :posts
  has_many :comments
  
  before_save do
    self.name.downcase!
  end
  
  validates :name, uniqueness: true, format: { with: /\A[a-zA-Z0-9]+\z/,
                                               message: "invalid name" }
  def to_param
    name
  end
  
  def self.find(input)
    find_by_name(input)
  end
  
  def self.search(search)
    where("LCASE(title) LIKE ?", "%#{ search.downcase }%") +
    where("LCASE(second_title) LIKE ?", "%#{ search.downcase }%")
  end
end
