class Video < ActiveRecord::Base
  belongs_to :category
  has_many :reviews, -> {order( "created_at DESC" )}
  has_many :queue_items
  validates_presence_of :title, :description

  mount_uploader :large_cover, LargeCoverUploader
  mount_uploader :small_cover, SmallCoverUploader
  
  def self.search_by_title(key_word)
    return [] if key_word.blank?
    self.where("title LIKE ?", "%#{key_word}%").order("created_at DESC")
  end

  def rating
    if self.reviews.count == 0
      nil
    else
      self.reviews.collect(&:rating).sum.to_f / self.reviews.count
    end
  end
end