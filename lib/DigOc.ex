defmodule DigOc do
  require DigOc.Raw

  # -- API Stuff.
  def clear_cache, do: DigOc.Cache.clear

  # -------------------------------------------------- /droplets
  defrecord Droplet,
    backups_active: nil,
    status: nil,
    private_ip_address: nil,
    name: nil,
    created_at: nil,
    image_id: nil,
    image: nil,
    locked: nil,
    id: nil,
    size_id: nil,
    size: nil,
    region_id: nil,
    region: nil,
    ip_address: nil,
    event_id: nil

  def droplet_action(id, action, params \\ nil) do
    res = DigOc.Raw.droplet_action(id, action, params)
    res["event_id"]
  end

  def droplets do
    res = DigOc.Raw.droplets
    Enum.map res["droplets"], fn(d) -> DigOc.Convert.to_droplet_record(d) end
  end

  def droplets(id) do
    res = DigOc.Raw.droplets id
    DigOc.Convert.to_droplet_record(res["droplet"])
  end

  def droplets(:new, params) do
    res = DigOc.Raw.droplets(:new, params)
    DigOc.Convert.to_droplet_record(res["droplet"])
  end

  def droplets(id, :reboot),         do: droplet_action(id, :reboot)
  def droplets(id, :power_cycle),    do: droplet_action(id, :power_cycle)
  def droplets(id, :power_off),      do: droplet_action(id, :power_off)
  def droplets(id, :power_on),       do: droplet_action(id, :power_on)
  def droplets(id, :password_reset), do: droplet_action(id, :password_reset)
  def droplets(id, :shutdown),       do: droplet_action(id, :shutdown)
  def droplets(id, :destroy),        do: droplet_action(id, :destroy)
    
  def droplets(id, :rename, name) do 
    droplet_action id, :rename, [name: name]
  end

  def droplets(id, :snapshot, snapshot_name) do
    droplet_action id, :snapshot, [name: snapshot_name]
  end

  def droplets(id, :restore, image) do
    id_or_slug = if is_record(image, DigOc.Image), do: image.id, else: image
    droplet_action(id, :restore, [image_id: id_or_slug])
  end

  def droplets(id, :resize, size) do
    id_or_slug = if is_record(size, DigOc.Size), do: size.id, else: size
    droplet_action(id, :resize, [size_id: id_or_slug])
  end
  
  def droplets(id, :rebuild, image) do
    id_or_slug = if is_record(image, DigOc.Image), do: image.id, else: image
    droplet_action(id, :rebuild, [image_id: id_or_slug])
  end


  # -- convenience methods.
  def droplet(name) when is_binary(name) do
    Enum.filter droplets, fn(d) -> d.name == name end
  end

  def droplet(id) when is_integer(id) do
    Enum.filter droplets, fn(d) -> d.id == id end
  end

  def execute_blocking_action(f, args \\ []) do
    evt = apply f, args
    event_progress evt
  end
    
  def power_off(id) do
    execute_blocking_action(fn() -> droplets id, :power_off end)
  end
  
  def power_on(id) do
    execute_blocking_action(fn() -> droplets id, :power_on end)
  end

  def power_off_action(droplet, f, args \\ []) do
     id = droplet.id
     beginning_state = droplet.status
     if beginning_state == "active", do: power_off(id)
     execute_blocking_action(f, args)
     if beginning_state == "active", do: power_on(id)
  end

  def take_snapshot(droplet, snapshot_name) do
    droplet = hd(droplet droplet)
    f = fn(id) -> droplets id, :snapshot, snapshot_name end
    power_off_action(droplet, f, [droplet.id])
    DigOc.Cache.clear
    hd(Enum.filter DigOc.images, fn(i) -> i.name == snapshot_name end)
  end
    
  def resize(droplet, size) do
    droplet = hd(droplet droplet)
    size = if is_record(size, DigOc.Size), do: size.id, else: size
    f = fn(id, size) -> droplets id, :resize, size end
    power_off_action(droplet, f, [droplet.id, size])
    droplet droplet.id
  end

  def restore(droplet, image) do
    droplet = hd(droplet droplet)
    image = if is_record(image, DigOc.Image), do: image.id, else: image
    f = fn(id, image) -> droplets id, :restore, image end
    power_off_action(droplet, f, [droplet.id, image])
    droplet droplet.id
  end

  def rebuild(droplet, image) do
    droplet = hd(droplet droplet)
    image = if is_record(image, DigOc.Image), do: image.id, else: image
    f = fn(id, image) -> droplets id, :rebuild, image end
    power_off_action(droplet, f, [droplet.id, image])
    droplet droplet.id
  end


  # -------------------------------------------------- /regions
  defrecord Region,
    name: nil,
    id: nil,
    slug: nil

  def regions do
    case DigOc.Cache.get :regions do
      :not_found ->
        res = DigOc.Raw.regions
        data = Enum.map res["regions"], 
                    fn(d) -> DigOc.Convert.to_region_record(d) end
        DigOc.Cache.update_cache :regions, data
      {:ok, data} -> data
    end
  end
  
  def region(id), do: DigOc.Cache.get(:regions, id, &DigOc.regions/0)

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
    case DigOc.Cache.get :images do
      :not_found ->
        res = DigOc.Raw.images
        data = Enum.map res["images"], 
                    fn(d) -> DigOc.Convert.to_image_record(d) end
        DigOc.Cache.update_cache :images, data
      {:ok, data} -> data
    end
  end

  def image(id) when is_integer(id) do
    DigOc.Cache.get(:images, id, &DigOc.images/0)
  end

  def images(id) do
    DigOc.Cache.clear
    image id
  end

  def images(id, :transfer, region) do
    res = DigOc.Raw.images id, :transfer, region_id: region
    res["event_id"]
  end

  def images(id, :destroy) do
    res = DigOc.Raw.images id, :destroy
    if res["status"] == "OK", do: :ok, else: :error
  end

  # -------------------------------------------------- /ssh_keys
  #
  # NB: Still using the "raw" format here.
  defrecord SSHKey,
    id: nil,
    name: nil,
    ssh_pub_key: nil

  def ssh_keys do
    res = DigOc.Raw.ssh_keys
    Enum.map res["ssh_keys"], 
         fn(d) -> DigOc.Convert.to_abbr_sshkey_record(d) end
  end

  def ssh_keys(id) do
    res = DigOc.Raw.ssh_keys(id)
    DigOc.Convert.to_sshkey_record(res["ssh_key"])
  end

  def ssh_keys(:add, params) do
    res = DigOc.Raw.ssh_keys :add, params
    DigOc.Convert.to_sshkey_record(res["ssh_key"])    
  end

  def ssh_keys(id, :destroy) do
    res = DigOc.Raw.ssh_keys id, :destroy
    case res["status"] do
      "OK" -> :ok
      _ -> :error
    end
  end

  def ssh_keys(id, :edit, params) do
    res = DigOc.Raw.ssh_keys id, :edit, params
    DigOc.Convert.to_sshkey_record(res["ssh_key"])
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
    case DigOc.Cache.get :sizes do
      :not_found ->
        res = DigOc.Raw.sizes
        data = Enum.map res["sizes"], 
                    fn(d) -> DigOc.Convert.to_size_record(d) end
        DigOc.Cache.update_cache :sizes, data
      {:ok, data} -> data
    end
  end
    
  def size(id), do: DigOc.Cache.get(:sizes, id, &DigOc.sizes/0)

  

  # -------------------------------------------------- /domains
  defrecord Domain,
    id: nil,
    name: nil,
    ttl: nil,
    live_zone_file: nil,
    error: nil,
    zone_file_with_error: nil

  defrecord DomainRecord,
    id: nil,
    domain_id: nil,
    record_type: nil,
    name: nil,
    data: nil,
    priority: nil,
    port: nil,
    weight: nil

  def domains do
    res = DigOc.Raw.domains
    Enum.map res["domains"],
         fn(d) -> DigOc.Convert.to_domain_record(d) end
  end

  def domains(id) do
    res = DigOc.Raw.domains id
    DigOc.Convert.to_domain_record(res["domain"])
  end

  def domains(:new, params) do
    res = DigOc.Raw.domains(:new, params)
    DigOc.Convert.to_domain_record(res["domain"])
  end

  def domains(id, :destroy) do
    res = DigOc.Raw.domains(id, :destroy)
    if res["status"] == "OK", do: :ok, else: :error
  end

  def domains(id, :records) do
    res = DigOc.Raw.domains(id, :records)
    Enum.map res["records"],
         fn(d) -> DigOc.Convert.to_domainrecord_record(d) end
  end

  def domains(id, :new_record, params) do
    res = DigOc.Raw.domains(id, :new_record, params)
    DigOc.Convert.to_domainrecord_record(res["record"])
  end

  def domains(id, :records, record_id) do
    res = DigOc.Raw.domains(id, :records, record_id)
    DigOc.Convert.to_domainrecord_record(res["record"])
  end
  
  def domains(id, :destroy_record, record_id) do
    res = DigOc.Raw.domains(id, :destroy_record, record_id)
    if res["status"] == "OK", do: :ok, else: :error
  end

  def domains(id, :edit_record, record_id, params) do
    res = DigOc.Raw.domains(id, :edit_record, record_id, params)
    DigOc.Convert.to_domainrecord_record(res["record"])
  end

  def domain(id) when is_integer(id), do: domains id

  def domain(name) when is_binary(name) do
    Enum.filter domains, fn(d) -> d.name == name end
  end

  # -------------------------------------------------- /events
  defrecord Event,
    id: nil,
    action_status: nil,
    droplet_id: nil,
    event_type_id: nil,
    percentage: nil

  def events(id) do
    res = DigOc.Raw.events(id)
    DigOc.Convert.to_event_record(res["event"])
  end

  def event_progress(id) when is_integer(id) do
    event = events id
    event_progress(event)
  end

  def event_progress(event) when is_record(event, DigOc.Event) do
    event = events event.id
    cond do
      event.percentage == "100" -> :ok
      event.action_status == "done" -> :ok
      true -> 
        :timer.sleep(20 * 1000)
        event_progress(event)
    end
  end
                                   

end
