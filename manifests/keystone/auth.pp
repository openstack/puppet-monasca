# == Class: monasca::keystone::auth
#
# Configures Monasca user, service and endpoint in Keystone.
#
# === Parameters
# [*auth_name*]
#    Username for Monasca service. Optional. Defaults to 'monasca'.
#
# [*admin_name*]
#    Username for Monasca admin service. Optional. Defaults to 'monasca-admin'.

# [*user_name*]
#    Username for vanilla Monasca user. Optional. Defaults to 'monasca-user'.
#    This user can read and write data for their tenant.
#
# [*agent_name*]
#    Username for Monasca agent service. Optional. Defaults to 'monasca-agent'.
#
# [*admin_password*]
#    Password for Monasca admin user. Required.
#
# [*user_password*]
#    Password for Monasca default user. Required.
#
# [*agent_password*]
#    Password for Monasca agent user. Required.
#
# [*admin_email*]
#   Email for Monasca admin user. Optional. Defaults to 'monasca@localhost'.
#
# [*agent_email*]
#   Email for Monasca agent user. Optional. Defaults to 'monasca@localhost'.
#
# [*user_email*]
#   Email for Monasca default. Optional. Defaults to 'monasca@localhost'.
#
# [*configure_endpoint*]
#   Should Monasca endpoint be configured? Optional. Defaults to 'true'.
#
# [*configure_user*]
#   Should Monasca service user be configured? Optional. Defaults to 'true'.
#
# [*configure_user_role*]
#   Should roles be configured on Monasca service user? Optional. Defaults to 'true'.
#
# [*service_name*]
#   Name of the service. Optional. Defaults to value of auth_name.
#
# [*service_type*]
#    Type of service. Optional. Defaults to 'monitoring'.
#
# [*public_address*]
#    Public address for endpoint. Optional. Defaults to '127.0.0.1'.
#
# [*admin_address*]
#    Admin address for endpoint. Optional. Defaults to '127.0.0.1'.
#
# [*internal_address*]
#    Internal address for endpoint. Optional. Defaults to '127.0.0.1'.
#
# [*port*]
#    Default port for enpoints. Optional. Defaults to '8082'.
#
# [*region*]
#    Region for endpoint. Optional. Defaults to 'RegionOne'.
#
# [*tenant*]
#    Tenant for Monasca user. Optional. Defaults to 'services'.
#
# [*public_protocol*]
#    Protocol for public endpoint. Optional. Defaults to 'http'.
#
# [*admin_protocol*]
#    Protocol for admin endpoint. Optional. Defaults to 'http'.
#
# [*internal_protocol*]
#    Protocol for public endpoint. Optional. Defaults to 'http'.
#
# [*public_url*]
#    The endpoint's public url.
#    Optional. Defaults to $public_protocol://$public_address:$port
#    This url should *not* contain any API version and should have
#    no trailing '/'
#    Setting this variable overrides other $public_* parameters.
#
# [*admin_url*]
#    The endpoint's admin url.
#    Optional. Defaults to $admin_protocol://$admin_address:$port
#    This url should *not* contain any API version and should have
#    no trailing '/'
#    Setting this variable overrides other $admin_* parameters.
#
# [*internal_url*]
#    The endpoint's internal url.
#    Optional. Defaults to $internal_protocol://$internal_address:$port
#    This url should *not* contain any API version and should have
#    no trailing '/'
#    Setting this variable overrides other $internal_* parameters.
#
class monasca::keystone::auth (
  $auth_name           = 'monasca',
  $admin_email         = 'monasca@localhost',
  $agent_email         = 'monasca@localhost',
  $user_email          = 'monasca@localhost',
  $configure_user      = true,
  $configure_user_role = true,
  $service_name        = undef,
  $service_type        = 'monitoring',
  $public_address      = '127.0.0.1',
  $admin_address       = '127.0.0.1',
  $internal_address    = '127.0.0.1',
  $tenant              = 'services',
  $public_protocol     = 'http',
  $admin_protocol      = 'http',
  $internal_protocol   = 'http',
  $configure_endpoint  = true,
  $public_url          = undef,
  $admin_url           = undef,
  $internal_url        = undef,
  $role_agent          = 'monasca-agent',
  $role_delegate       = 'monitoring-delegate',
  $role_user           = 'monasca-user',
) {
  include monasca::params

  $admin_name = $::monasca::params::admin_name
  $agent_name = $::monasca::params::agent_name
  $user_name = $::monasca::params::user_name
  $admin_password = $::monasca::params::admin_password
  $agent_password = $::monasca::params::agent_password
  $user_password = $::monasca::params::user_password
  $port = $::monasca::params::port
  $api_version = $::monasca::params::api_version
  $region = $::monasca::params::region

  if $public_url {
    $public_url_real = $public_url
  } else {
    $public_url_real = "${public_protocol}://${public_address}:${port}/${api_version}"
  }

  if $admin_url {
    $admin_url_real = $admin_url
  } else {
    $admin_url_real = "${admin_protocol}://${admin_address}:${port}/${api_version}"
  }

  if $internal_url {
    $internal_url_real = $internal_url
  } else {
    $internal_url_real = "${internal_protocol}://${internal_address}:${port}/${api_version}"
  }

  if $service_name {
    $real_service_name = $service_name
  } else {
    $real_service_name = $auth_name
  }

  if $configure_user {
    keystone_user { $admin_name:
      ensure   => present,
      password => $admin_password,
      email    => $admin_email,
      tenant   => $tenant,
      before   => Python::Pip['monasca-agent'],
    }
    keystone_user { $agent_name:
      ensure   => present,
      password => $agent_password,
      email    => $agent_email,
      tenant   => $tenant,
      before   => Python::Pip['monasca-agent'],
    }
    keystone_user { $user_name:
      ensure   => present,
      password => $user_password,
      email    => $user_email,
      tenant   => $tenant,
      before   => Python::Pip['monasca-agent'],
    }
  }

  if $configure_user_role {
    Keystone_user_role["${admin_name}@${tenant}"] ~>
      Service <| name == 'monasca-api' |>
    Keystone_user_role["${agent_name}@${tenant}"] ~>
      Service <| name == 'monasca-api' |>
    Keystone_user_role["${user_name}@${tenant}"] ~>
      Service <| name == 'monasca-api' |>

    if !defined(Keystone_role[$role_agent]) {
      keystone_role { $role_agent:
        ensure => present,
      }
    }
    if !defined(Keystone_role[$role_delegate]) {
      keystone_role { $role_delegate:
        ensure => present,
      }
    }
    if !defined(Keystone_role[$role_user]) {
      keystone_role { $role_user:
        ensure => present,
      }
    }
    keystone_user_role { "${agent_name}@${tenant}":
      ensure  => present,
      roles   => [$role_agent, $role_delegate],
      require => [Keystone_role[$role_agent], Keystone_role[$role_delegate]],
      before  => Python::Pip['monasca-agent'],
    }
    keystone_user_role { "${admin_name}@${tenant}":
      ensure => present,
      roles  => ['admin'],
      before => Python::Pip['monasca-agent'],
    }

    keystone_user_role { "${user_name}@${tenant}":
      ensure  => present,
      roles   => [$role_user],
      require => Keystone_role[$role_user],
      before  => Python::Pip['monasca-agent'],
    }
  }

  keystone_service { $real_service_name:
    ensure      => present,
    type        => $service_type,
    description => 'Openstack Monitoring Service',
  }
  if $configure_endpoint {
    keystone_endpoint { "${region}/${real_service_name}":
      ensure       => present,
      public_url   => $public_url_real,
      admin_url    => $admin_url_real,
      internal_url => $internal_url_real,
    }
  }
}
