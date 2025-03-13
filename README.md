# UP Box 4 Configuration Tool

[![shellcheck](https://github.com/usableprivacy/config/actions/workflows/shellcheck.yml/badge.svg?branch=main)](https://github.com/usableprivacy/config/actions/workflows/shellcheck.yml)
___
This tool installs and configures the basic building blocks of the **[Usable Privacy Box (v4)](https://upribox.org)**.<br>
Use this tool to **filter ads and trackers** in your home network and to **protect your DNS traffic** against analysis and monitoring.

**Notable Building Blocks**

- [Knot Resolver](https://github.com/CZ-NIC/knot-resolver) for `caching` and `DNS over TLS (DoT)`
- [Pi-hole®](https://github.com/pi-hole/pi-hole) for network-wide `ad blocking`.
- [UP Config Utility](https://github.com/usableprivacy/config)  for configuration via `CLI`

**DNS Configuration Options**<br>

[Knot Resolver](https://knot-resolver.readthedocs.io/en/stable/) provides `caching`, `DNSSEC validation`, `QNAME Minimization`, and `IPv6 support` by default.

The UP Box Configuration Tool ships four different DNS configurations:

- `plain`: Unencrypted DNS to [Cloudflare](https://www.cloudflare.com/dns/) and [Google](https://developers.google.com/speed/public-dns).
- `recursive`: Recursive resolver with unencrypted DNS to [Authoritative DNS server](https://en.wikipedia.org/wiki/Domain_Name_System#Authoritative_name_server).
- `mix`: **Encrypted DNS** over TLS split between [Cloudflare](https://www.cloudflare.com/dns/), [Applied Privacy](https://applied-privacy.net/services/dns/), [Digitale Gesellschaft](https://www.digitale-gesellschaft.ch/dns/), [Quad9](https://www.quad9.net/).
- `private`: **Encrypted DNS** over TLS split between [Applied Privacy](https://applied-privacy.net/services/dns/), [Digitale Gesellschaft](https://www.digitale-gesellschaft.ch/dns/).

The four configuration options are loosely sorted by the privacy-protection they offer.
The `plain` configuration is the least privacy-friendly option but may offer the best performance. The `private` configuration offers the strongest privacy protection.
We recommend the `mix` configuration for the best balance between privacy and performance.

___

## `up-config`

### Installation

The UP Box 4 Configuration Tool primarily powers upriboxes based on [armbian](https://www.armbian.com/).<br>
Any **Debian-based distribution** with **[NetworkManager](https://en.wikipedia.org/wiki/NetworkManager)** *may* work just fine.

#### `curl https://raw.githubusercontent.com/usableprivacy/config/main/install.sh | bash`

### Command Line Interface (CLI)

#### `up-config dns`

Change the DNS mode after the initial setup.

#### `up-config init`

Start the initial up-config configuration.

#### `up-config reset`

Reset up-config settings to default.

#### `up-config update`

Update the up-config configuration utility.

___

(C) [NysosTech e.U.](https://nysos.net) 2025
