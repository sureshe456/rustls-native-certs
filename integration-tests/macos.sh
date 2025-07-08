#!/bin/bash

set -ex

ANY_CA_PEM=integration-tests/one-existing-ca.pem
ANY_CA_SUBJECT="OU=GlobalSign Root CA - R3, O=GlobalSign, CN=GlobalSign"

reset() {
  #sudo security remove-trusted-cert -d $ANY_CA_PEM || true
  CERT_HASH=$(openssl x509 -in $ANY_CA_PEM -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':')
  echo "Attempting to delete cert with hash: $CERT_HASH"
  sudo security find-certificate -Z $CERT_HASH /Library/Keychains/System.keychain || echo "Cert not found"
  sudo security delete-certificate -Z $CERT_HASH /Library/Keychains/System.keychain || echo "Delete failed"
  list | grep "$ANY_CA_SUBJECT"
}

list() {
  cargo test util_list_certs -- --nocapture 2>/dev/null
}

assert_missing() {
  set +e
  list | grep "$1"
  ret=$?
  set -e
  test $ret -eq 1
}

assert_exists() {
  list | grep "$1" > /dev/null
}

test_distrust_existing_root() {
  assert_exists "$ANY_CA_SUBJECT"
  #sudo security add-trusted-cert -d -r deny $ANY_CA_PEM
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $ANY_CA_PEM

  assert_missing "$ANY_CA_SUBJECT"
  reset
}

# https://developer.apple.com/forums/thread/671582?answerId=693632022#693632022
sudo security authorizationdb write com.apple.trust-settings.admin allow

#security find-certificate -a -c "GlobalSign"
sudo security find-certificate -a -c "GlobalSign" /Library/Keychains/System.keychain || echo "Not found"
#sudo security find-certificate -Z D69B561148F01C77C54578C10926DF5B856976AD /Library/Keychains/System.keychain
#CERT_HASH=$(openssl x509 -in $ANY_CA_PEM -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':')
#sudo security find-certificate -Z 2CC6581C672A56552B5080963BCD53E2012194A3 /Library/Keychains/System.keychain

reset
test_distrust_existing_root
printf "\n*** All tests passed ***\n"
