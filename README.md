# OwnTone for Home Assistant (HAOS add-on)

A HAOS add-on that runs [OwnTone](https://owntone.org/) — the formerly **MPD** music
server — inside a supervised container with:

- **mpd protocol on port 6600** — connect from HA's mpd integration, mpdroid,
  ncmpc, or any other mpd client.
- **mpdweb web UI on port 9000** — a browser client bundled with OwnTone.
- **Replaygain on port 6601**.
- **PulseAudio socket** — HA can play audio *through* OwnTone on its Home Speakers
  via the `mpd` integration's "custom player" mechanism, or from HA TTS by adding
  `media_source://http://<ha>:9000/web/owntone.mp3` (see README's *TTS via mpdweb*).
- Music directory exposed at `/data/owntone` on the container; mount any host
  folder you like into `music_dir` at add-on install time.

## Layout

```
owntone/
├── config.yaml          # add-on manifest (arch, ports, options schema)
├── Dockerfile           # builds on top of mpdai/owntone:latest
├── entrypoint.sh        # stages default config, applies /config/owntone.conf
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
# produces build/owntone-1.0.0.tar.gz

# Copy the directory into your HAOS add-ons folder:
sudo cp -r owntone /mnt/user/addons/local/owntone
# Then in HA → Settings → Add-ons → gear → "Add add-on repository URL":
#     /mnt/user/addons/local
```

### Option B — build image + use MPP / custom repo

```bash
export DOCKER_REGISTRY=ghcr.io/yourhandle
export ADDON_VERSION=1.0.0
./build.sh --all --push
```

Register the add-on repository URL in HA (typically a Git repo URL or a
`/mnt/user/addons/` folder) and install from there.

## First run

1. Start the add-on from HA.
2. Browse to the web UI URL shown in the add-on card (default
   `http://<HA-host>:9000/web`).
3. Add your music by copying files into the `music_dir` you specified at install
   time (default `/data/owntone`).
4. In mpdweb, click **Library → Update** to build the tag cache.

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

## Configuration (mpd.conf)

A sane default `mpd.conf` is written on the **first** start to
`/etc/mpd.conf`. If you want to customise it:

1. Stop the add-on.
2. In the add-on's advanced settings (config.yaml's `options`), set
   `config_dir` to a file on the host, e.g. `/mnt/user/addons/owntone.conf`.
3. Create that file with your `mpd.conf` content.
4. Start the add-on — `entrypoint.sh` will copy it over the default.

## Firewall / networking

By default OwnTone binds to `0.0.0.0` inside the container. HA's add-on
networking restricts inbound access from the host (`172.30.0.0/8`) to the
ports declared in `config.yaml` (6600, 6601, 9000). If you want Other LAN
devices to connect directly:

- Set the add-on's network mode to `host` in its settings, **or**
- Use port forwarding on the HA host to the add-on's host-side port.

Restrict which hosts can connect by setting the `mpd_interface_whitelist`
option (e.g. `192.168.0.0/16;10.0.0.0/8`).

## Architecture support

`amd64`, `armv7`, `armhf`, `aarch64` — same as the base `mpdai/owntone` image.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `mpd` won't start, "bind: Address already in use" | Another mpd is running. Stop it or change `MPD_PORT`. |
| HA mpd integration can't connect | Make sure the add-on is running and the `mpd_interface_whitelist` allows HA's docker bridge (`172.30.0.0/8`). |
| Web UI 404 | The `mpd-httpd` process serves from `/web`; confirm `httpd_root` option is `/web`. |
| No audio output | Enable PulseAudio output in the options, and make sure the HA host has PulseAudio working. |
| Library is empty | Use **Library → Update** in mpdweb, or wait for `auto_update` (30 min interval by default). |

## License

This add-on is distributed under the same terms as OwnTone (Apache-2.0).
The base image `mpdai/owntone` is by [mpdai](https://github.com/mpdai/owntone).
