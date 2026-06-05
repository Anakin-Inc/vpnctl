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
vpnctl update               # upgrade vpnctl itself to the latest from this repo
```

The profile name is auto-derived from the file if you omit it.

## Updating

The installer turns on **auto-update by default** — a `launchd` timer runs
`vpnctl update` daily and at every boot, so devices stay current with no action.
This only swaps the `vpnctl` binary; it never disrupts running tunnels.

```sh
vpnctl autoupdate status        # is it on? when did it last run?
vpnctl autoupdate on [hours]    # enable / change interval (default 24h)
vpnctl autoupdate off           # disable
vpnctl update                   # update now, manually (cache-busted, shows before/after)
```

`vpnctl update` pulls the latest from this repo over your installed copy (cache-busted,
so it gets the true latest even right after a push). Re-running the `curl … | bash`
installer does the same thing.

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

Already have the Pritunl client installed with your profile? **You don't need a URL or
file at all** — `vpnctl install` with no arguments picks up Pritunl's already-downloaded
profile automatically:

```sh
vpnctl install              # auto-pick the installed Pritunl profile
vpnctl install anakin-vpn   # if you have several, pick one by name
```

It also **auto-detects and stops** the running Pritunl connection to the same server, so
the two don't fight over the tunnel. To force-stop a specific profile, pass
`--stop-pritunl <profile-id>` (ids: `pritunl-client list`).

## Notes

- macOS + Homebrew OpenVPN only.
- Profiles using static cert auth work standalone. Profiles requiring interactive/SSO/OTP
  auth on every connect are not a fit for an unattended daemon.
- **No secrets live in this repo.** You provide your own profile at `vpnctl install` time.
