class School < ActiveRecord::Base
  include PgSearch
  has_one :badge
  has_many :users, -> { where('role = ? OR role = ?', 1, 3) }
  has_many :events, dependent: :destroy
  acts_as_taggable

  #reverse_geocoded_by :latitude, :longitude, :address => :address
  #after_validation :reverse_geocode

  pg_search_scope :search_full_text, against: {
    school_name: 'A',
    loc_addr: 'B',
    loc_city: 'A',
    loc_state: 'B',
  }

  def handle_abbr
    value = self.school_name
    if value == nil
      return nil
    end
    value = value.titlecase
    abbr = {"Sch" => " School ", "Ln" => "Lane", "Elem" => "Elementary"}
    values = value.split(" ")
    newvalues =[]
    values.each do |v|
      if abbr[v] != nil
	newvalues += [abbr[v]]
      else
	newvalues += [v]
      end
    end
    newvalues.join(" ")
  end
end
