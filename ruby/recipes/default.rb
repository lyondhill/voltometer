include_recipe 'apt'
include_recipe 'build-essential'
include_recipe 'ruby_build'

node[:ruby][:deps].each do |pkg|
  package pkg do
    action :install
  end
end

ruby_build_ruby node[:ruby][:version] do
  action :install
end

template '/etc/profile.d/ruby.sh' do
  source 'ruby.sh.erb'
  variables :ruby_path => "#{node['ruby_build']['default_ruby_base_path']}/#{node[:ruby][:version]}/bin"

  mode '0644'
end

gem_package 'bundler' do
  action :install
  version '1.2.1'
  gem_binary "#{node['ruby_build']['default_ruby_base_path']}/#{node[:ruby][:version]}/bin/gem"
end
