default[:rails_env] = node.chef_environment.sub("_default", "production")

default[:distiller][:user] = "distiller"
default[:distiller][:group] = "distiller"
default[:distiller][:name] = "distiller"
default[:distiller][:repository] = "git://gkellogg/rdf-distiller.git"
default[:distiller][:document_root] = "/var/www/rack-apps/distiller"

default[:distiller][:ruby_version] = "2.0.0-p247"
