defmodule DigOc do
  import DigOc.Utility, only: [qs: 1, ssh_key_id: 1]

  # -------------------------------------------------- /droplets
  def droplets do
    {:ok, res} = DigOc.Client.get("/droplets").body
    res
  end

  # -------------------------------------------------- /regions
  defrecord Region,
    name: nil,
    id: nil,
    slug: nil

  def regions do
    res = DigOc.Raw.regions
    Enum.map res["regions"], fn(d) -> DigOc.Convert.to_region_record(d) end
  end

  # -------------------------------------------------- /images
  defrecord Image, 
    name: nil,
    distribution: nil,
    id: nil,
    region_slugs: [],
    slug: nil,
    public: nil,
    regions: nil
    
  def images do
    res = DigOc.Raw.images
    Enum.map res["images"], fn(d) -> DigOc.Convert.to_image_record(d) end
  end


  # -------------------------------------------------- /ssh_keys
  def ssh_keys do
    {:ok, res} = DigOc.Client.get("/ssh_keys").body
    res
  end

  def ssh_keys(id) do
    {:ok, res} = DigOc.Client.get("/ssh_keys/#{ ssh_key_id id }").body
    res
  end

  def ssh_keys(:add, params) do
    {:ok, res} = DigOc.Client.get("/ssh_keys/new/" <> qs(params)).body
    res
  end

  def ssh_keys(id, :destroy) do
    {:ok, res} = DigOc.Client.get("/ssh_keys/#{ ssh_key_id id}/destroy").body
    res
  end

  def ssh_keys(id, :edit, params) do
    url = "/ssh_keys/#{ ssh_key_id id }/edit/" <> qs(params)
    {:ok, res} = DigOc.Client.get(url).body
    res
  end


  # -------------------------------------------------- /sizes
  defrecord Size, 
    cost_per_hour: nil, 
    cost_per_month: nil,
    name: nil, 
    id: nil,
    memory: nil,
    slug: nil,
    cpu: nil,
    disk: nil
  
  def sizes do
    res = DigOc.Raw.sizes
    Enum.map res["sizes"], fn(d) -> DigOc.Convert.to_size_record(d) end
  end
    
end
