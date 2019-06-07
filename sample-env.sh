# DOKKU_DOMAIN represents the high level domain for your instance
DOKKU_DOMAIN="example.com"

# DOKKU_SUBDOMAIN is a sub-level you might want to attach to
DOKKU_SUBDOMAIN="instance"

# DOKKU_HOSTNAME can be set to the hostname that will host your
# Dokku instance. It defaults to something sensible based on
# DOKKU_SUBDOMAIN and DOKKU_DOMAIN anyway
#
# DOKKU_HOSTNAME="instance.example.com"

# This is a path to the key that allows direct SSH access to the host
# of your Dokku instance.
DOKKU_KEY="$HOME/.ssh/id_rsa-dokku"

# The following variables should not need to be set in general, the
# values in the examples are the default ones
#
# DOKKU_VHOST_ENABLE='true'
# DOKKU_WEB_CONFIG='false'
# DOKKU_KEY_FILE='/root/.ssh/authorized_keys'

# If you don't provide a DOKKU_IP, then an instance will be created
# automatically.

# VM_PROVIDER is a string representing the name of the VM provider. Look
# for corresponding values in "new-vm.d", each script (without the ".sh"
# extension) is a valid value.
VM_PROVIDER='digital-ocean'

# DNS_PROVIDER is a string representing the name of the DNS provider. Look
# for valid values in "dns.d", each script (without the ".sh" extension) is
# good.
DNS_PROVIDER='cloudns'

# For VM_PROVIDER='digital-ocean'
DO_TOKEN='your-password-here'
DO_SSH_KEY_ID='your-ssh-key-id-here'
DO_IMAGE='debian-9-x64'
DO_REGION='fra1'
DO_SIZE='s-1vcpu-1gb'

# for DNS_PROVIDER='cloudns'
CLOUDNS_AUTH='sub-auth-id= *ID-HERE* &auth-password= *PASSWORD-HERE*'
# you might also use "auth-id" instead of "sub-auth-id"
