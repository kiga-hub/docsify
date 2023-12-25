# Prometheus Data Backup and Recovery

## Description

Prometheus saves the collected data in a time series manner to memory (in the TSDB time series database), and periodically saves it to the hard disk.

Prometheus's storage layer uses the concept of 'inverted index' in full-text search, viewing each time series as a small document. 
The metrics and labels correspond to the words in the document.

Prometheus stores data in blocks, with each unit being 2 hours, first stored in memory, and then automatically written to disk.

## Backup

Backup Directory Structure:

```
|----01FYYE46DJ5GPVQ8K5V5A4YSCN
    |----chunks:     Multiple save timeseries data
        |----000001
        |----000002
    |----meta.json:  Configuration file, includes start and end time, includes those blocks
    |----index:      Find the location of time series data in the chunk file through metric names and labels
    |----tombstones: The delete operation first records this file
|----wal: Mechanism to prevent data loss due to program abnormalities, including checkpoints and other logs
```

## Recovery

1. Copy the backup data directory to the data directory of the Prometheus system

    ```bash
    scp -r 01* IP:/var/lib/prometheus/
    ```

2. restart Prometheus

```bash
systemctl stop prometheus
/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus --storage.tsdb.retention.time=30d --storage.tsdb.retention.size=0 --web.console.libraries=/etc/prometheus/console_libraries --web.console.templates=/etc/prometheus/consoles --web.listen-address=0.0.0.0:9090 --web.external-url=  
```

The log shows that healthy data blocks are found, indicating that the data import was successful。

```bash
level=info ts=2020-10-09T08:10:19.104Z caller=repair.go:56 component=tsdb msg="Found healthy block" mint=1601337600000 maxt=1601402400000 ulid=01EKDTMK8BAG4W8129H6NF6SP2
level=info ts=2020-10-09T08:10:19.104Z caller=repair.go:56 component=tsdb msg="Found healthy block" mint=1601402400000 maxt=1601467200000 ulid=01EKFRE3F8ZW89G3P8ZKHK5R7M
level=info ts=2020-10-09T08:10:19.104Z caller=repair.go:56 component=tsdb msg="Found healthy block" mint=1601467200000 maxt=1601532000000 ulid=01EKHP7MFQS2NK3HTDK8T00401
level=info ts=2020-10-09T08:10:19.104Z caller=repair.go:56 component=tsdb msg="Found healthy block" mint=1601532000000 maxt=1601596800000 ulid=01EKKM15XMZN1A4QSXV6V60PGV
```

Visit webpage

[http://ip:9090/](http://ip:9090/)

Enter sum(http_requests_total) in the UI interface query box, and it should be able to display data normally。

## Data backup and restoration through the API method is more efficient.

### Copy Data

Prometheus provides snapshot backup, which is more efficient than backing up the data directory

Implementation Method: `BasicNode` = "node"

```
# Need to modify the Prometheus startup parameters, add the following two parameters
--storage.tsdb.path=/share/{BasicNode}/prometheus/data \
--web.enable-admin-api    
```

Call the API for quick backup, data will be quickly backed up to data/snapshots
```
# Do not skip the data in memory, that is, backup the data in memory at the same time
curl -XPOST http://127.0.0.1:9090/api/v2/admin/tsdb/snapshot?skip_head=false
# Skip the data in memory
curl -XPOST http://127.0.0.1:9090/api/v2/admin/tsdb/snapshot?skip_head=true

Return Result：  
{"status":"success","data":{"name":"20191220T012427Z-21e0e532e8ca3423"}}
```

### Data Recovery

After making a snapshot using the API method, restore the files in the snapshot to the data directory and restart Prometheus.
