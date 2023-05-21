require "test_helper"
require "clients/r_m_api"

class RMApiTest < ActiveSupport::TestCase
  def setup
    @char = {
      "id" => 1,
      "name" => "Chuck",
      "status" => "Berry",
      "species" => "Human",
      "gender" => "Male",
      "image" => "http://test.example/img.jpg",
      "episode" => [
        {"episode" => "S01E01"},
        {"episode" => "S02E03"},
        {"episode" => "S02E04"},
        {"episode" => "S02E10"}
      ]
    }
  end


  test "parsing the data" do
    parsed = Character.new(RMApi.parse(@char))
    char = characters(:one)

    assert_equal parsed.name, char.name
    assert_equal parsed.status, char.status
    assert_equal parsed.species, char.species
    assert_equal parsed.gender, char.gender
    assert_equal parsed.appearances, char.appearances
  end
end
