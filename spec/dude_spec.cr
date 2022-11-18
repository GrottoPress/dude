require "./spec_helper"

private struct User
  include JSON::Serializable

  getter cache_key : String
  getter id : Int32

  def initialize(@id)
    @cache_key = "users:#{id}"
  end
end

describe Dude do
  it "fetches data from cache" do
    user_id = 2
    user = User.new(user_id)

    Dude.set(user.cache_key, user.to_json, 5.seconds)
    Dude.get(User, user.cache_key).try(&.id).should eq(user_id)
  end

  it "writes data to cache if not found" do
    user_id = 2
    user = User.new(user_id)

    value = Dude.get(User, user.cache_key, 1.second) { User.new(user_id) }
    value.try(&.id).should eq(user_id)
  end

  it "deletes data from cache" do
    key = "key"
    value = "value"

    Dude.set(key, value, nil)
    Dude.get(key).should eq(value)

    Dude.delete(key)
    Dude.get(key).should be_nil
  end
end
