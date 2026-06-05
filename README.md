# vpnctl

Always-on OpenVPN for macOS. Each VPN profile runs as its own `launchd` daemon, so it
**starts at boot, respawns within seconds if it dies, and self-heals stale tunnels**
(sleep/wake, wifi roam) via OpenVPN `ping-restart` — no GUI client, no babysitting.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Anakin-Inc/vpnctl/main/install.sh | bash
```

Installs the `vpnctl` command (and OpenVPN via Homebrew if missing). `sudo` prompts on
your terminal. The only prerequisite is [Homebrew](https://brew.sh).

## Use

```sh
# Add a VPN. Source = an .ovpn path, a .zip path, or a Pritunl key URL.
vpnctl install https://vpn.example.com/key/XXXXXXXX.zip work

vpnctl list                 # all profiles + running state
vpnctl status   work        # daemon state, routes, gateway ping
vpnctl restart  work        # force a fresh reconnect
vpnctl logs     work        # live tail
vpnctl stop     work
vpnctl start    work
vpnctl uninstall work       # remove daemon + config + log
```

The profile name is auto-derived from the file if you omit it.

## How it stays on

| Failure | Recovery |
| --- | --- |
| Stale tunnel (sleep/wake, wifi roam) | OpenVPN `ping 5 / ping-restart 20` re-handshakes in ~20s |
| Process death (crash, fatal error) | `launchd KeepAlive` respawns in ~5s |
| Reboot | `launchd RunAtLoad` starts it at boot |

## What it installs (per profile `<name>`)

| Artifact | Path |
| --- | --- |
| Hardened config | `/etc/vpnctl/<name>.ovpn` |
| launchd daemon | `/Library/LaunchDaemons/com.vpn.<name>.plist` |
| Log | `/var/log/vpn-<name>.log` |

The config is your profile plus always-on hardening: `persist-tun`, `persist-key`,
faster `ping-restart`, `resolv-retry infinite`, `connect-retry`.

## Pritunl

Migrating off the Pritunl client? Pass `--stop-pritunl <profile-id>` to `vpnctl install`
to stop and disable the competing Pritunl connection (find the id with
`/Applications/Pritunl.app/Contents/Resources/pritunl-client list`).

## Notes

- macOS + Homebrew OpenVPN only.
- Profiles using static cert auth work standalone. Profiles requiring interactive/SSO/OTP
  auth on every connect are not a fit for an unattended daemon.
- **No secrets live in this repo.** You provide your own profile at `vpnctl install` time.
