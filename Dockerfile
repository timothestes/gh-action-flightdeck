FROM catthehacker/ubuntu:act-20.04

# copy in Netskope certificate 
COPY ca-certificates/nscacert.pem /usr/local/share/ca-certificates/nscacert.crt
RUN update-ca-certificates