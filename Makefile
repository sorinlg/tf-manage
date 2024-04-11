DOCKER_IMAGE = "ghcr.io/sorinlg/tf-manage:main"

docker-build:
	docker build --platform=linux/amd64 -t $(DOCKER_IMAGE) .

docker-push: docker-build
	docker push $(DOCKER_IMAGE)

docker-run: docker-build
	docker run --platform=linux/amd64 -it --rm $(DOCKER_IMAGE) bash

