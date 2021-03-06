# Deprecated!

Hi -- There's a new Elixir library, digoc, available via hex or
[on GitHub](https://github.com/kevinmontuori/digoc) that speaks D.O.'s API v2.  (Plus my Elixir programming got, I hope, better!)  Drop me a line if you have questions.

# DigitalOcean API Client in Elixir

## Introduction

A pretty straightforward implementation of the
[DigitalOcean API](https://cloud.digitalocean.com/api_access) (login
required) in [Elixir](http://elixir-lang.org).  We've tried to keep
the behavior consistent with how it's described in the documentation
but have provided a few potentially helpful convenience methods where
appropriate.

There are tests included; be warned that they create and destroy
DigitalOcean resources!  Running them can incur charges or even
destroy existing droplets so please, don't run them blindly.

## Documentation

To get started, be sure to set the environment variables
`DIGITAL_OCEAN_CLIENT_ID` and `DIGITAL_OCEAN_API_KEY`.  

This library closely follows the DigialOcean API document.  One
convenience provided is the translation of JSON return structures into
Elixir records.  So

    event_record = DigOc.event event_id
    IO.puts event_record.action_status

and the like are possible.

### Droplets


* List all the droplets.

        droplet_list = DigOc.droplets

* Get a droplet by ID.

        droplet = DigOc.droplets id

* Create a new droplet.  Returns a record representing the newly
  created droplet (though most of the records will be nil until the
  droplet creation event, specified by droplet.event_id, has
  completed).

          region_id = 1             # nyc
          size_id = 66              # very small!
          image_id = 350076         # ubuntu 13.04/x64
          name = "apitest"
          backups = false
          private_networking = false
          ssh_key_ids = [79152]     # a priv key
      
          droplet = DigOc.droplets :new, 
                          region_id: region_id,
                          size_id: size_id,
                          image_id: image_id,
                          name: name,
                          backups: backups,
                          private_networking: private_networking,
                          ssh_key_ids: ssh_key_ids

* Reboot a droplet.  Returns an event_id.

        DigOc.droplets droplet.id, :reboot

* Power cycle a droplet.  Returns an event_id.

        DigOc.droplets droplet.id, :powercycle

* Shutdown a droplet.  Returns an event_id.

        DigOc.droplets droplet.id, :shutdown

* Power off a droplet.  Returns an event_id.

        DigOc.droplets droplet.id, :power_off

* Power on a droplet.  Returns an event_id.

        DigOc.droplets droplet.id, :power_on

* Reset a droplet password.  Returns an event_id.

        DigOc.droplets droplet.id, :password_reset

* Destroy a droplet.  Returns an event_id.

        DigOc.droplets droplet.id, :destroy


These functions require a running droplet to be powered off before
executing.  There are both plain methods that do not manipulate the
droplet first and convenience methods that will power off a running
server, perform the action, and power the server back on again (if it
was running).

* Resize a droplet.  The `size` parameter can be either a size record
  (as would be returned by `DigOc.sizes` or a size.id or size.slug.

        # plain
        evt = DigOc.droplets droplet.id, :resize, size

        # convenience
        droplet = DigOc.resize droplet, size


* Take a snapshot.

        # plain
        evt = DigOc.droplets droplet.id, :snapshot, snapshot_name

        # convenience
        new_image = DigOc.take_snapshot droplet, snapshot_name

* Restore a droplet from an image.  The `image` parameter can be
  either an image record (as would be returned by `DigOc.images` or an
  image.id or image.slug.

        # plain
        evt = DigOc.droplets droplet.id, :restore, image

        # convenience
        droplet = DigOc.restore droplet, image

* Rebuild a droplet from an image.  The `image` parameter is as above.

        # plain
        evt = DigOc.droplets droplet.id, :rebuild, image

        # convenience
        droplet = DigOc.rebuild droplet, image


* Get a droplet by ID or name.  (Convenience)

        droplet = DigOc.droplet id_or_name

    
### Regions

Note: Regions are cached.  If a new region becomes available it will
not appear in the region list until the cache is cleared.

* Get the available regions as a list of DigOc.Region records.

        regions = DigOc.regions

* Get the Region record for a given region_id.

        region = DigOc.region region_id


### Images

Note: Images are cached.  If a new image is created (by taking a
snapshot, say) the cache should be cleared afterwards.

* Get the available images as a list of DigOc.Image records.

        images = DigOc.images

* Get the Image record for a given image_id.

        image = DigOc.image image_id


### SSH Keys

* Get the available public SSH keys as a list of DigOc.SSHKey records.

        keys = DigOc.ssh_keys

* Get an ssh key by ID.

        key = DigOc.ssh_keys key_id

* Create a new SSH key.

        public_key = "ssh-rsa AAAAB3Nzac1...XXV user@example.com"
        key = DigOc.ssh_keys :add, name: "new key", ssh_pub_key: public_key

* Edit an SSH key.

        key = DigOc.ssh_keys sshkey.id, :edit, name: "new name"

* Destroy an SSH key.

        :ok = DigOc.ssh_keys sshkey.id, :destroy


### Sizes

Note: sizes are cached.  If a new size becomes available it not appear
in the size list until the cache is cleared.

* Get the available sizes as a list of DigOc.Size records.

        sizes = DigOc.sizes

* Get the Size record for a given size_id.

        size = DigOc.size size_id

### Events

* Get the DigOc.Event record for an event_id.

        evt = DigOc.events event_id

* Block until an event has a percentage of "100" or an action_status
  of "done".  Accepts either an Event record or event id.

        :ok = DigOc.event_progress event_record
        :ok = DigOc.event_progress event_id

### Domains

* Get a list of all the domains.

        domain_list = DigOc.domains

* Get a domain by id.

        domain_record = DigOc.domains id

* Create a new domain.

        domain_record = DigOc.domains :new, params

* Destroy a domain.

        :ok = DigOc.domains id, :destroy

* Get a list of records for a domain.

        records = DigOc.domains id, :records

* Create a new record.

        record = DigOc.domains id, :new_record, params

* Get a specific record by id.

        record = DigOc.domains id, :records, record_id

* Destroy a record.

        :ok = DigOc.domains id, :destroy_record, record_id

* Edit a record.

        record = DigOc.domains id, :edit_record, record_id, params

* Get a record by name or id.  (Convenience)

        record = DigOc.domain id_or_name


### Cache

* To clear the cache (asynchronously):

        DigOc.clear_cache


## Author

Kevin Montuori <montuori@gmail.com>
  
