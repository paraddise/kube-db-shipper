REPOSITORY ?= docker.io/appapa/kds

PGDUMP_IMG ?= ${REPOSITORY}-pgdump
AWSCLI_IMG ?= ${REPOSITORY}-awscli

.PHONY: docker-build
docker-build:
	docker build -t ${PGDUMP_IMG} -f build/dockerfiles/Dockerfile-pgdump .
	docker build -t ${AWSCLI_IMG} -f build/dockerfiles/Dockerfile-awscli .

.PHONY: docker-push
docker-push:
	docker push ${PGDUMP_IMG}
	docker push ${AWSCLI_IMG}


.PHONY: kube-deploy-starter-pack
kube-deploy-starter-pack:
	helm upgrade --install --set "auth.database=test-database" --set "auth.username=test-user" --set "auth.password=test-password" --set "tls.enabled=true" --set="tls.autoGenerated=true" postgresql oci://registry-1.docker.io/bitnamicharts/postgresql
	helm upgrade --install --set "auth.rootPassword=test-password" minio oci://registry-1.docker.io/bitnamicharts/minio

.PHONY: helm-template
helm-template:
	helm template --output-dir render --validate kube-db-shipper helm-charts/kube-db-shipper --dependency-update

.PHONY: helm-upgrade
helm-upgrade:
	helm upgrade --install kube-db-shipper helm-charts/kube-db-shipper --set schedule="*/2 * * * *"

.PHONY: awscli-sh
awscli-sh:
	docker run -ti --rm --entrypoint sh -v ./test/dumps:/data --env-file test/.awscli.env -v ./build/rotate_s3.sh:/bin/rotate_s3.sh ${AWSCLI_IMG}
