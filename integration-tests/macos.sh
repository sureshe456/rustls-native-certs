#!/bin/bash

set -ex

ANY_CA_PEM=integration-tests/one-existing-ca.pem
ANY_CA_SUBJECT="OU=GlobalSign Root CA - R3, O=GlobalSign, CN=GlobalSign"



#reset() {
  #CERT_HASH=$(openssl x509 -in $ANY_CA_PEM -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':')
  #echo "Attempting to delete cert with hash: $CERT_HASH"
  #if ! sudo security find-certificate -Z "$CERT_HASH" /Library/Keychains/System.keychain > /dev/null 2>&1; then
    #echo "Certificate with hash $CERT_HASH not found in System keychain, skipping delete."
  #else
    #sudo security delete-certificate -Z "$CERT_HASH" /Library/Keychains/System.keychain || echo "Delete failed"
  #fi

  #list | grep "$ANY_CA_SUBJECT"
#}

reset() {
  #security remove-trusted-cert -d $ANY_CA_PEM || true
  security remove-trusted-cert -d /Library/Keychains/System.keychain -c $ANY_CA_PEM
  list | grep "$ANY_CA_SUBJECT"
}


#reset() {
  #SUBJECT="OU=GlobalSign Root CA - R3, O=GlobalSign, CN=GlobalSign"
  #echo "Attempting to delete cert with subject: $SUBJECT"
  
  # Find SHA-1 hash by subject SHA-1 hash
  #CERT_HASH=$(sudo security find-certificate -c "GlobalSign Root CA - R3" -Z /Library/Keychains/System.keychain | \
    #grep "SHA-1 hash:" | awk '{print $3}')
  
  #CERT_HASH=$(openssl x509 -in integration-tests/one-existing-ca.pem -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)
  #if [ -z "$CERT_HASH" ]; then
    #echo "No matching certificate found to delete"
    #return
  #fi

  #echo "Deleting certificate with hash: $CERT_HASH"
  #sudo security delete-certificate -Z "$CERT_HASH" /Library/Keychains/System.keychain || echo "Delete failed"
  #list | grep "$ANY_CA_SUBJECT"
  #list | grep "$ANY_CA_SUBJECT" || true

#}


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
  sudo security add-trusted-cert -d -r deny $ANY_CA_PEM   # this line is correct
  assert_missing "$ANY_CA_SUBJECT"
  reset
}

# https://developer.apple.com/forums/thread/671582?answerId=693632022#693632022
sudo security authorizationdb write com.apple.trust-settings.admin allow

reset
test_distrust_existing_root
printf "\n*** All tests passed ***\n"
