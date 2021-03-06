#!/usr/bin/env ruby
#
# Cookbook Name:: ruby
# Recipe:: source
#

case node['platform_family']
when "rhel"
  include_recipe "yum::epel" # if node['platform_version'].to_i < 6
  pkgs = %w{ libxslt-devel libtool libxml2-devel gdbm-devel libffi-devel zlib-devel openssl-devel readline-devel curl-devel pcre-devel }
when "debian"
  pkgs = %w{ libxslt-dev libyaml-dev libxml2-dev libgdbm-dev libffi-dev zlib1g-dev libssl-dev libreadline-dev libcurl4-openssl-dev libpcre3-dev }
else
  return "#{node['platform']} is not supported by the #{cookbook_name}::#{recipe_name} recipe"
end

pkgs.each do |pkg|
  package pkg
end

include_recipe "build-essential"
include_recipe "libyaml::source" if node['platform_family'] == "rhel"

rver = node['ruby']['ruby_version']
gver = node['ruby']['rubygems_version']
sloc = node['ruby']['source_location']
ssrc = node['ruby']['source_cache_dir']
ddir = node['ruby']['destination_dir']

rtar = "ruby-#{rver}.tar.gz"
gtar = "rubygems-#{gver}.tgz"

## ruby
remote_file "#{ssrc}/#{rtar}" do
  source "#{sloc}/#{rtar}"
  mode 0644
  action :create_if_missing
end

execute "tar --no-same-owner -xzf #{rtar}" do
  cwd ssrc
  creates "#{ssrc}/ruby-#{rver}"
end

execute "configure ruby" do
  command "./configure"
  cwd "#{ssrc}/ruby-#{rver}"
  creates "#{ssrc}/ruby-#{rver}/Makefile"
end

execute "make ruby" do
  command "make"
  cwd "#{ssrc}/ruby-#{rver}"
  creates "#{ssrc}/ruby-#{rver}/bin/ruby"
end

execute "make install ruby" do
  command "make install"
  cwd "#{ssrc}/ruby-#{rver}"
  not_if {File.exists?("#{ddir}/ruby") && `#{ddir}/ruby --version`.chomp =~ /#{rver.gsub("-", "")}/}
  creates "#{ddir}/ruby"
end

## ruby-gems
remote_file "#{ssrc}/#{gtar}" do
  source "http://production.cf.rubygems.org/rubygems/#{gtar}"
  mode 0644
  action :create_if_missing
end

execute "tar --no-same-owner -xzf #{gtar}" do
  cwd ssrc
  creates "#{ssrc}/rubygems-#{gver}"
end

execute "install rubygems" do
  command "#{ddir}/ruby setup.rb"
  cwd "#{ssrc}/rubygems-#{gver}"
  creates "#{ddir}/gem"
end

# vim: filetype=ruby
