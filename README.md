# Kube-db-shipper

Make backups of databases easily.
## Local testing
Create kind cluster
```bash
kind create cluster
```

Deploy postgres and minio
```bash
make kube-deploy-starter-pack
```

Deploy backup shipper and make backup every 2 minute

```bash
make helm-upgrade
```

## Roadmap

### Backup utils
- [x] pgdump
- [ ] [barman](https://pgbarman.org/)
- [ ] [mysql](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)
- [ ] [etcd](https://etcd.io/docs/v3.3/op-guide/recovery/)
- [ ] redis (somehow)
- [ ] [mongodump](https://www.mongodb.com/docs/database-tools/mongodump/)
- [ ] [clickhouse](https://clickhouse.com/docs/en/operations/backup)
- [ ] custom configuration

### Mutate utils
- [ ] [openssl encrypt](https://wiki.openssl.org/index.php/Enc)
- [ ] [gpg encrypt](https://www.gnupg.org/gph/en/manual/x110.html)
- [ ] [gzip compression](https://www.gnu.org/software/gzip/)

### Ship utils
- [x] [aws s3](https://docs.aws.amazon.com/cli/latest/reference/s3/) with rotation

