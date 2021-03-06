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
  
  test "query string creation" do
    params = [foo: "bar", baz: "quux"]
    qs = "?foo=bar&baz=quux"
    assert DigOc.Utility.qs(params) == qs
 end


  test "cache record conversion" do
    defrecord A, id: nil, name: nil
    recs = [A.new(id: 1, name: "foo"),
            A.new(id: 2, name: "bar"),
            A.new(id: 3, name: "baz")]
    hash = DigOc.Convert.to_cache_record(recs)
    assert hash[1].name == "foo"
    assert hash[2].name == "bar"
    assert hash[3].name == "baz"
  end

  test "/droplets" do
    res = DigOc.Raw.droplets
    assert res["status"] == "OK"
    
    droplets = DigOc.droplets
    assert is_list(droplets)
    assert is_record(hd(droplets), DigOc.Droplet)

    # -- single droplet test:
    drop = hd(droplets)
    new_drop_1 = DigOc.droplet(drop.id) |> hd
    new_drop_2 = DigOc.droplet(drop.name) |> hd
    assert drop == new_drop_1
    assert drop == new_drop_2
  end
  
  test "/regions" do
    res = DigOc.Raw.regions
    assert res["status"] == "OK"
    
    regions = DigOc.regions
    assert is_list(regions)
    assert is_record(hd(regions), DigOc.Region)
  end

  test "/images" do
    res = DigOc.Raw.images
    assert res["status"] == "OK"

    images = DigOc.images
    assert is_list(images)
    assert is_record(hd(images), DigOc.Image)
  end

  test "/ssh_keys" do
    res = DigOc.Raw.ssh_keys
    assert res["status"] == "OK"
    
    keys = DigOc.ssh_keys
    assert is_list(keys)
    assert is_record(hd(keys), DigOc.SSHKey)
  end

  test "create, lookup, destroy ssh key" do
    key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSAFOCkXC61jeb/L8FeDn8nfb5bre5ph3a1vvHWvs7amQw7JIgy3rP6uqPZabJCNWxGdORGP5lNNwdQ1s7hdteQvoUlPTg1WXFr7ZJ9pUNuAB0nyasY+7tEzJWJvXAUx7eZOhxI7qfgH0E9AAkMpqZ6o9uQfu2Ov8uAj2tXQNtXbkn0N4jOXqJvIXY9MJu7/FTH6TReeQyJoUfUAhlDWXmtE+T7YySyVDzOprM41tXGY5KUYgPQUAWXNVzAkMdlLf6dU9HIRvzEgYMkL+ka0W25gEaQlgas8gahkDuKVaT/5WkOcEaf3HnM+NMNPwXw626IB/w/Y9BCTHczDspoKbB montuori@joe-cool.local"

    # -- add the key
    res = DigOc.ssh_keys :add, name: "testkey2", ssh_pub_key: key
    assert is_record(res, DigOc.SSHKey)
    assert res.name == "testkey2"
    assert res.ssh_pub_key == key

    # -- lookup the key's id
    id = DigOc.Utility.ssh_key_id("testkey2")
    assert is_integer(id)

    # -- fetch the key
    sshkey = DigOc.ssh_keys id
    assert sshkey.name == "testkey2"

    # -- edit the key
    sshkey = DigOc.ssh_keys id, :edit, ssh_pub_key: key
    assert sshkey.name == "testkey2"
    
    # -- delete the key
    res = DigOc.ssh_keys id, :destroy
    assert res == :ok

    # -- ensure the key is deleted
    res = DigOc.ssh_keys id, :destroy
    assert res == :error
  end
    
  
  test "get sizes" do
    res = DigOc.Raw.sizes
    assert res["status"] == "OK"

    sizes = DigOc.sizes
    assert is_list(sizes)
    assert is_record(hd(sizes), DigOc.Size)
  end
  

end
