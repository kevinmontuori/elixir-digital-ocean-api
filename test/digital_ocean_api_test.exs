defmodule DigitalOceanApiTest do
  use ExUnit.Case

  HTTPotion.start

  test "client id retrieved" do
    assert DigOc.Utility.client_id
  end

  test "api key retrieved" do
    assert DigOc.Utility.api_key
  end

  test "url correct" do
    assert DigOc.Utility.url == "https://api.digitalocean.com/"
  end

  test "path fabricated correctly" do
    path = "a/b/c"
    assert DigOc.Utility.path(["a", "b", "c"]) == path
    assert DigOc.Utility.path(['a', 'b', 'c']) == path
    assert DigOc.Utility.path([:a, :b, :c])    == path
    assert DigOc.Utility.path("") == ""
    assert DigOc.Utility.path([]) == ""
  end


  test "/droplets" do
    res = DigOc.droplets
    assert res["status"] == "OK"
  end
  
  test "/regions" do
    res = DigOc.regions
    assert res["status"] == "OK"
  end

  test "/images" do
    res = DigOc.images
    assert res["status"] == "OK"
  end

end
