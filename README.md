# OwnTone for Home Assistant (HAOS add-on)

A HAOS add-on that runs [OwnTone](https://owntone.org/) — the formerly **MPD** music
server — inside a supervised container with:

- **MPD protocol on port 6600** — connect from HA's mpd integration, mpdroid,
  ncmpc, or any other mpd client.
- **Web UI on port 3689** — browser-based music library manager (same port as DAAP).
- **DAAP protocol on port 3689** — stream to Apple Music / iTunes via AirPlay.
- **HA ingress sidebar** — Web UI appears as a sidebar panel in the HA dashboard.
- **Configurable admin password** — set via the `admin_password` option in the
  add-on's configuration. Leave empty to use the default password `changeme`.
- Music directory at `/media` inside the container (host: `/mnt/data/supervisor/media`).

## Layout

```
owntone/
├── config.yaml          # add-on manifest (arch, ports, options schema)
├── Dockerfile           # builds on top of lscr.io/linuxserver/daapd:28.10.20250118
├── icon.svg             # icon shown in HA add-ons UI
├── build.sh             # docker build + tar.gz packaging helper
├── translations/
│   ├── en.yaml
│   └── zh-Hans.yaml
├── README.md
└── build/               # tar.gz output after ./build.sh --all
```

## Building

You can either build locally and install as a manual add-on, or push a Docker
image and let Home Assistant build the add-on from it.

### Option A — build & install manually (no registry needed)

```bash
cd owntone
./build.sh --all
# produces build/owntone-1.0.8.tar.gz

# Copy the directory into your HAOS add-ons folder:
sudo cp -r owntone /mnt/user/addons/local/owntone
# Then in HA → Settings → Add-ons → gear → "Add add-on repository URL":
#     /mnt/user/addons/local
```

### Option B — build image + use MPP / custom repo

```bash
export DOCKER_REGISTRY=ghcr.io/yourhandle
export ADDON_VERSION=1.0.8
./build.sh --all --push
```

Register the add-on repository URL in HA (typically a Git repo URL or a
`/mnt/user/addons/` folder) and install from there.

## First run

1. Start the add-on from HA.
2. Browse to the web UI URL shown in the add-on card (default
   `http://<HA-host>:3689/`).
3. Add your music by copying files into the `music_dir` you specified at install
   time (default `/media` inside container, maps to `/mnt/data/supervisor/media` on host).
4. In the Web UI, click **Library → Update** to build the tag cache.

## Home Assistant integration

The simplest integration path:

1. **Settings → Devices & Services → Add integration → mpd.**
2. Host: `http://homeassistant.local` (or the HA host IP on your network).
3. Port: `6600`.
4. Save. An **OwnTone** media_player entity appears, e.g.
   `media_player.owntone`.

You can then:

- Play/stop/pause/next/previous from the HA UI.
- Use Home Assistant automations to play media on a schedule.
- **Play TTS / audio through it**: any `media_player.play_media` with
  `media_content_id` set to a stream URL will play via OwnTone.

### Playing HA TTS through OwnTone

```yaml
service: media_player.play_media
target:
  entity_id: media_player.owntone
data:
  media_content_id: >-
    http://homeassistant.local:8123/api/stream?token=<YOUR_LONG_LIVED_TOKEN>
  media_content_type: audio/mpeg
```

Or simpler with `tts.media_player`:

```yaml
service: tts.media_player
target:
  entity_id:
    - media_player.owntone
    - text_to_speech.edge
data:
  message: Hello from Home Assistant, playing through OwnTone.
```

## Configuration

The add-on supports the following configuration options:

### Options

- `mpd_port` (default: `6600`) - MPD protocol TCP port
- `daap_port` (default: `3689`) - DAAP/Web UI TCP port
- `music_dir` (default: `/media`) - Music library directory
- `playlist_dir` (default: `/media`) - Playlist directory
- `admin_password` (default: `""`) - Web UI admin password
- `autostart` (default: `false`) - Start add-on when HA starts

### Admin password

The Web UI (port 3689) requires a password for authentication. By default, the
password is `changeme`. To change it:

1. Stop the add-on.
2. Go to the add-on's configuration page.
3. Set the `admin_password` option to your desired password.
4. Start the add-on.

If you leave `admin_password` empty, the default password `changeme` will be used.

> **Note**: If you access the Web UI from within trusted networks (LAN CIDR
> `192.168.0.0/24`), authentication is not required. The password is only needed
> when accessing from outside trusted networks.

## Firewall / networking

By default OwnTone binds to `0.0.0.0` inside the container. HA's add-on
networking restricts inbound access from the host (`172.30.0.0/8`) to the
ports declared in `config.yaml` (6600, 3689, 3688).

### Trusted networks

The add-on is configured to trust the LAN CIDR `192.168.0.0/24`. Devices within
this network range can access the Web UI without authentication.

To access the Web UI from outside trusted networks:

1. Set the `admin_password` option to a secure password.
2. Forward port 3689 on your router/firewall.
3. Access via `http://<your-external-ip>:3689`.

## Architecture support

`aarch64`, `amd64`

## Troubleshooting

| Symptom | Fix |
|---|---|
| `mpd` won't start, "bind: Address already in use" | Another mpd is running. Stop it or change `mpd_port`. |
| HA mpd integration can't connect | Make sure the add-on is running and the HA host can reach port 6600. |
| Web UI 401 Unauthorized | Set `admin_password` or access from within trusted networks. |
| No audio output | Enable `audio: true` in config.yaml and ensure PulseAudio is working. |
| Library is empty | Use **Library → Update** in the Web UI, or wait for `auto_update`. |

## License

This add-on is distributed under the same terms as OwnTone (Apache-2.0).
The base image `lscr.io/linuxserver/daapd` is by [LinuxServer.io](https://linuxserver.io).
