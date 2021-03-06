class User < ActiveRecord::Base
  has_many :blogs
  has_many :ratings
  attr_accessor :login

  include Gravtastic
  gravtastic

  acts_as_followable
  acts_as_follower

  devise :omniauthable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :omniauth_providers => [:facebook],
         :authentication_keys => [:login]

  validates :username,
    :presence => true,
    :uniqueness => {
    :case_sensitive => false
  }
  
  def self.from_omniauth(auth)
  where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.username = auth.info.name.downcase.delete(' ')
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.is_female = auth.extra.raw_info.gender == "male" ? false : true
      user.skip_confirmation!
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def send_user_notifier post
    UserNotifier.new_post(post).deliver_later
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      if conditions[:username].nil?
        where(conditions).first
      else
        where(username: conditions[:username]).first
      end
    end
  end
  
  def facebook_user?
    self.provider == "facebook"
  end
    
  def to_param
    username
  end
  
  def self.find(input)
    find_by_username(input)
  end
  
  def post_count
   Post.where(:user_id => id).count.to_s
  end
  
  def comment_count
   Comment.where(:user_id => id).count.to_s
  end
end
