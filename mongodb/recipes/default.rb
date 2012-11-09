#
#
#

if platform? 'ubuntu'
  
  file '/etc/apt/sources.list.d/10gen.list' do
    content <<-END
      deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen
      END
  end

  execute "add_10gen_key" do
    command "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10"
    notifies :run, "execute[apt-get update]", :immediately
    not_if { `apt-key list | grep "10gen" | wc -l`.to_i != 0 }
  end

  execute "apt-get update" do
    action :nothing
  end

end

package "mongodb-10gen"

service "mongodb" do
  action [:enable, :start]
end