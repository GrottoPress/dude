require "./spec_helper"

describe "no store", tags: {"skip_around_each"} do
  before_each do
    Dude.settings.store = nil
  end

  it "fetches nothing from cache" do
    key = :key
    value = "value"

    Dude.set(key, value, 5.seconds)
    Dude.get(key).should be_nil
  end

  it "writes nothing to cache if not found" do
    key = :key
    value = "value"

    cached_value = Dude.get(key, 1.second) { value }
    cached_value.should eq(value.to_json)

    Dude.get(key).should be_nil
  end

  it "deletes nothing from cache" do
    Dude.delete("key").should be_nil
  end

  it "supports transactions" do
    key = :key
    key_2 = :key2

    value = "value"
    value_2 = "value2"

    Dude.transaction do |store|
      Dude.set(key, value, nil, store)
      Dude.set(key_2, value_2, nil, store)
      Dude.delete(:key_3, store)
    end

    Dude.get(key).should be_nil
    Dude.get(key_2).should be_nil
  end
end
