#
# Cookbook Name:: distiller
# Recipe:: defeault
#
#

include_recipe "distiller::rbenv"

# FIXME: Setting from languages['ruby']['gems_dir'] does not pick up installed ruby
node.normal['passenger']['root_path'] = "#{node[:rbenv][:root]}/versions/#{node[:distiller][:ruby_version]}/lib/ruby/gems/2.0.0/gems/passenger-#{node['passenger']['version']}"
node.normal['passenger']['module_path'] = "#{node['passenger']['root_path']}/buildout/apache2/mod_passenger.so"

group node[:distiller][:group]

user node[:distiller][:user] do
  comment "distiller daemon user"
  group node[:distiller][:group]
  system true
  shell "/bin/bash"
end

# FIXME: On first run, passenger is not setup with rbenv version of passenger
# FIXME: This is from passenger_apache2, but apache fails before this is run
node.set['passenger']['version'] = "4.0.21"

rbenv_gem "passenger" do
  version node['passenger']['version']
end

#include_recipe "apache2"
#package "httpd-devel"
#if node['platform_version'].to_f < 6.0
#  package 'curl-devel'
#else
#  package 'libcurl-devel'
#  package 'openssl-devel'
#  package 'zlib-devel'
#end
#
## FIXME: This fails to run on first attempt, as it can't find the executable
#execute "distiller_passenger" do
#  command "passenger-install-apache2-module --auto"
#  creates node['passenger']['module_path']
#end
#
#include_recipe "passenger_apache2"

application node[:distiller][:name] do
  path        node[:distiller][:document_root]
  owner       node[:distiller][:user]
  group       node[:distiller][:group]
  repository  node[:distiller][:repository]
  create_dirs_before_symlink %w(tmp)

  rails do
    bundler true
    precompile_assets false
    use_omnibus_ruby false
  end

  passenger_apache2
end
