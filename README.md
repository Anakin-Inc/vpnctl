# vpnctl

Always-on OpenVPN for macOS. Each VPN profile runs as its own `launchd` daemon, so it
**starts at boot, respawns within seconds if it dies, and self-heals stale tunnels**
(sleep/wake, wifi roam) via OpenVPN `ping-restart` — no GUI client, no babysitting.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Anakin-Inc/vpnctl/main/install.sh | bash
```

Installs the `vpnctl` command and its dependencies — **auto-installs Homebrew and OpenVPN
if they're missing**. `sudo` prompts on your terminal. No prerequisites. (`vpnctl install`
also self-installs OpenVPN if it's somehow absent, so it works no matter how `vpnctl` got
onto the machine.)

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

## Coexisting with another VPN (e.g. Cloudflare WARP)

If you run a full-tunnel VPN like **Cloudflare WARP** alongside vpnctl, it can take over
routing and **steal vpnctl's internal routes** when it reconnects (WARP excludes private
`10/8`/`172.16/12`/`192.168/16` ranges, dumping them back to your local interface). Symptom:
the tunnel shows `running` but internal hosts time out.

Turn on the **route-watchdog** for that profile — it checks every 30s that the pushed
routes are still on the tunnel and re-asserts them if something stole them:

```sh
vpnctl watch work            # enable (default every 30s)
vpnctl watch work 60         # custom interval (seconds)
vpnctl watch work status     # is it on? recent re-asserts
vpnctl watch work off        # disable
```

A one-off `vpnctl restart <name>` also fixes a stolen route immediately; the watchdog
just makes it self-healing.

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
