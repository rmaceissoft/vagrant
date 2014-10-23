#
# Cookbook Name:: pelias
# Recipe:: geonames
#

directory node[:pelias][:geonames][:data_dir] do
  owner  node[:pelias][:user][:name]
  group  node[:pelias][:user][:name]
  mode   0755
end

deploy "#{node[:pelias][:basedir]}/pelias-geonames" do
  user        node[:pelias][:user][:name]
  repository  node[:pelias][:geonames][:repository]
  revision    node[:pelias][:geonames][:revision]
  migrate     false

  symlink_before_migrate.clear
  create_dirs_before_symlink %w(tmp public config deploy)

  notifies :run, 'execute[npm install pelias-geonames]', :immediately
  only_if { node[:pelias][:geonames][:index_data] == true }
end

execute 'npm install pelias-geonames' do
  action  :nothing
  user    node[:pelias][:user][:name]
  command 'npm install'
  cwd     "#{node[:pelias][:basedir]}/pelias-geonames/current"
  environment('HOME' => node[:pelias][:user][:home])
end

# download and load, using the downloaded file
#   as an additional guard against a re-load.
#
node[:pelias][:geonames][:country_codes].each do |country|
  # execute "download geonames for #{country}" do
  #  user    node[:pelias][:user][:name]
  #  command "./bin/pelias-geonames -d #{country} >#{node[:pelias][:basedir]}/logs/geonames_#{country}.log 2>&1"
  #  cwd     "#{node[:pelias][:basedir]}/pelias-geonames/current"
  #  timeout node[:pelias][:geonames][:timeout]
  #  environment(
  #    'HOME' => node[:pelias][:user][:home],
  #    'PELIAS_CONFIG' => "#{node[:pelias][:cfg_dir]}/#{node[:pelias][:cfg_file]}"
  #  )
  #  notifies :run, "execute[load geonames for #{country}]", :immediately
  #  only_if { node[:pelias][:geonames][:index_data] == true && !::File.exist?("#{node[:pelias][:geonames][:data_dir]}/#{country}.zip") }
  # end

  execute "load geonames for #{country}" do
    action  :run # action :nothing TODO: revert to :nothing when geonames download works
    user    node[:pelias][:user][:name]
    command "./bin/pelias-geonames -i #{country} >#{node[:pelias][:basedir]}/logs/geonames_#{country}.log 2>&1"
    cwd     "#{node[:pelias][:basedir]}/pelias-geonames/current"
    timeout node[:pelias][:geonames][:timeout]
    environment(
      'HOME' => node[:pelias][:user][:home],
      'PELIAS_CONFIG' => "#{node[:pelias][:cfg_dir]}/#{node[:pelias][:cfg_file]}"
    )
    only_if { node[:pelias][:geonames][:index_data] == true }
  end
end
