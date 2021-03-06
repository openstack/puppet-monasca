# == Class: monasca::alarmdefs
#
# Class for bootstrapping monasca alarm definitions
#
# === Parameters:
#
# [*alarm_definition_config_source*]
#   location of alarm definitions template to bootstrap in mysql database
#
# [*notification_config_source*]
#   location of notification methods template to bootstrap in mysql database
#
# [*notification_assignments_source*]
#   location of notification assignments template to bootstrap in mysql database
#
# [*admin_username*]
#   name of the monasca admin user
#
# [*admin_password*]
#   password of the monasca admin user
#
# [*api_server_url*]
#   monasca api server endpoint
#
# [*auth_url*]
#   keystone endpoint
#
# [*project_name*]
#   keystone project name to bootstrap alarm definitions for
#
# [*virtual_env*]
#   location of python virtual environment to install to
#
## DEPRECATED PARAMS
#
# [*install_python_deps*]
#   flag for whether or not to install python dependencies
#
# [*python_dep_ensure*]
#   flag for whether or not to ensure/update python dependencies
#
class monasca::alarmdefs(
  $alarm_definition_config_source = 'monasca/alarm_definition_config.json.erb',
  $notification_config_source = 'monasca/notification_config.json.erb',
  $notification_assignments_source = 'monasca/notification_assignments.json.erb',
  $admin_username = 'monasca-admin',
  $admin_password = undef,
  $api_server_url = undef,
  $auth_url = undef,
  $project_name = undef,
  $virtual_env = '/var/www/monasca-alarmdefs',
  ## DEPRECATED PARAMS
  $install_python_deps     = undef,
  $python_dep_ensure       = undef,
)
{
  include monasca::params

  if $install_python_deps {
    warning('monasca::alarmdefs::install_python_deps is deprecated and has no effect')
  }
  if $python_dep_ensure {
    warning('monasca::alarmdefs::python_dep_ensure is deprecated and has no effect')
  }

  $alarm_definition_config = '/tmp/alarm_definition_config.json'
  $notification_config = '/tmp/notification_config.json'
  $notification_assignments = '/tmp/notification_assignments.json'
  $script_name = 'bootstrap-alarm-definitions.py'
  $script = "${virtual_env}/bin/${script_name}"
  $cleanup_script = "${virtual_env}/bin/vm_alarm_cleanup.py"
  $sql_host = $::monasca::params::sql_host
  $sql_user = $::monasca::params::sql_user
  $sql_password = $::monasca::params::sql_password
  $sql_port = $::monasca::params::sql_port

  python::virtualenv { $virtual_env :
    owner   => 'root',
    group   => 'root',
    before  => [Exec[$script], File[$script]],
    require => [Package['virtualenv'],Package['python-dev']],
  }

  file { $script:
    ensure  => file,
    content => template("monasca/${script_name}.erb"),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { $alarm_definition_config:
    ensure  => file,
    content => template($alarm_definition_config_source),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { $notification_config:
    ensure  => file,
    content => template($notification_config_source),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { $notification_assignments:
    ensure  => file,
    content => template($notification_assignments_source),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  exec { $script:
    subscribe   => [File[$script], File[$alarm_definition_config], File[$notification_config], File[$notification_assignments]],
    path        => '/bin:/sbin:/usr/bin:/usr/sbin:/tmp',
    cwd         => "${virtual_env}/bin",
    user        => 'root',
    group       => 'root',
    environment => ["OS_AUTH_URL=${auth_url}",
                    "OS_USERNAME=${admin_username}",
                    "OS_PASSWORD=${admin_password}",
                    "OS_PROJECT_NAME=${project_name}",
                    "MONASCA_API_URL=${api_server_url}"],
    refreshonly => true,
    require     => Service['monasca-api'],
  }

  file { $cleanup_script:
    ensure  => file,
    content => template('monasca/vm_alarm_cleanup.py.erb'),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Python::Virtualenv[$virtual_env],
  }

}
