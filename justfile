# load the .env file (if present)
set dotenv-load
# allow positional-arguments
set positional-arguments

list_all:
    act -l
@run test_name:
    act -s GITHUB_TOKEN="$(gh auth token)" -j $1

python:
  #!/usr/bin/env python3
  print('Hello from python!')

ca_certs:
    @echo 'Copying NetSkope CA cert into project...'
    cp /Library/Application\ Support/Netskope/STAgent/download/nscacert.pem ./ca-certificates/nscacert.pem
    mkdir -p ./data_tools/ca-certificates
    cp /Library/Application\ Support/Netskope/STAgent/download/nscacert.pem ./data_tools/ca-certificates/nscacert.pem