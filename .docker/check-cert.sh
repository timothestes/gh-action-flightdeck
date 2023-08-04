#! /bin/bash

CERT_FOLDER=data_tools/ca-certificates
CERT_FILE=$CERT_FOLDER/nscacert.pem

# on osx only check to make sure the cert has been copied into the repo
if [[ "$OSTYPE" == "darwin"* && ! -f "$CERT_FILE" ]]; then
  echo "Run 'make ca_certs' to fetch the Netskope CA certificate" && exit 1
else
  # workaround until we can bake the Netskope certs into our docker images. This will
  # create an empty file so the docker copy doesn't fail in CI.
  mkdir -p $CERT_FOLDER
  touch $CERT_FILE
fi
