# OwnTone add-on for HAOS — base image IS OwnTone (s6-overlay /usr/sbin/owntone).
# MPD protocol stays on 6600.
# Web UI enabled: -w flag serves built-in web interface on 3689 (same as DAAP).
# Admin password: set via ADMIN_PASSWORD env var (empty = default "changeme").
# Scheme B: trusted_networks = LAN CIDR 192.168.0.0/24 (passwordless on LAN).
FROM lscr.io/linuxserver/daapd:28.10.20250118

# Enable Web UI (-w flag) on 3689, set music dir to /media, and add admin_password override
# The init-daapd-config script will override admin_password at runtime if ADMIN_PASSWORD env is set
RUN sed -i 's|/usr/sbin/owntone -f|/usr/sbin/owntone -f -w /usr/share/owntone/htdocs|' \
    /etc/s6-overlay/s6-rc.d/svc-forked/run \
 && sed -i 's#directories = { "/srv/music" }#directories = { "/media" }#' \
    /etc/owntone.conf.orig \
 && sed -i 's#{ "lan" }#{ "192.168.0.0/24" }#' \
    /etc/s6-overlay/s6-rc.d/init-daapd-config/run \
 # Add admin_password override logic to init script (runs on container start)
 && cat >> /etc/s6-overlay/s6-rc.d/init-daapd-config/run << 'EOF'
# Override admin_password if ADMIN_PASSWORD env var is set
if [ -n "${ADMIN_PASSWORD:-}" ]; then
    sed -i "s/admin_password = .*/admin_password = \"$ADMIN_PASSWORD\"/" /etc/owntone.conf.orig
    echo "Admin password overridden via ADMIN_PASSWORD env var"
else
    echo "Admin password not set, using default"
fi
EOF
 && echo "=== Dockerfile patches applied ===" \
 && echo "1. Web UI enabled (-w flag):" \
 && grep "owntone -f" /etc/s6-overlay/s6-rc.d/svc-forked/run \
 && echo "2. Music directory set to /media:" \
 && grep "directories" /etc/owntone.conf.orig \
 && echo "3. trusted_networks set to LAN:" \
 && grep "trusted_networks" /etc/s6-overlay/s6-rc.d/init-daapd-config/run \
 && echo "4. Admin password override logic added:" \
 && tail -10 /etc/s6-overlay/s6-rc.d/init-daapd-config/run

EXPOSE 6600 3689 3688
