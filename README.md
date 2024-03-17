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

| Dumper | Mutator | Shipping |
---
| pgdump | |

