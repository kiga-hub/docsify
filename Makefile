.PHONY: setup run

setup:
	npm i docsify-cli -g

run:
	docsify serve &

pdf_not_working:
	docker run --rm -it \
  --cap-add=SYS_ADMIN \
  --user $(shell id -u):$(shell id -g) \
  -v ${shell pwd}:/home/node/docs:ro \
  -v ${shell pwd}:/home/node/pdf:rw \
  -e "PDF_OUTPUT_NAME=DOCUMENTATION.pdf" \
  ghcr.io/kernoeb/docker-docsify-pdf:latest