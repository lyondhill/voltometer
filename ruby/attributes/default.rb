default[:ruby][:version] = '1.9.3-p286'

default['ruby_build']['git_ref'] = 'v20121020'

case platform
when "debian", "ubuntu"
  default[:ruby][:deps] = %w[
    automake
    libcurl4-openssl-dev
    libmagickwand-dev
    libtool
    ncurses-dev
    pkg-config
  ]
else
  default[:ruby][:deps] = []
end