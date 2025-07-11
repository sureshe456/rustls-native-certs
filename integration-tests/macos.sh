#!/bin/bash

set -ex

ANY_CA_PEM=integration-tests/one-existing-ca.pem
ANY_CA_SUBJECT="OU=GlobalSign Root CA - R3, O=GlobalSign, CN=GlobalSign"

reset() { 
  CERT_HASH=$(openssl x509 -in $ANY_CA_PEM -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)
  security delete-certificate -Z "$CERT_HASH" /Library/Keychains/System.keychain || true
  list | grep "$ANY_CA_SUBJECT" || true
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
  security add-trusted-cert -d -r deny $ANY_CA_PEM
  assert_missing "$ANY_CA_SUBJECT"
  reset
}

security authorizationdb write com.apple.trust-settings.admin allow

reset
test_distrust_existing_root
printf "\n*** All tests passed ***\n"
