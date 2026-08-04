#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "[+] Updating packages..."
pkg update -y

echo "[+] Installing dependencies..."
pkg install -y wget termux-api

echo "[+] Wake lock..."
termux-wake-lock || true


mkdir -p ~/xray
cd ~/xray


echo "[+] Killing old Xray..."

pkill -f "xray run" || true


echo "[+] Downloading custom ARM32 Xray..."

rm -f xray

wget -q \
https://github.com/NaixROOT/KomaruCraft/releases/download/xd/xray-arm32 \
-O xray


chmod +x xray


echo "[+] Checking Xray..."

./xray version || {
    echo "[!] Xray binary is broken"
    exit 1
}


echo "[+] Creating socks.json..."

cat > socks.json <<'EOF'
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF


echo "[+] Creating reverse.json..."

cat > reverse.json <<'EOF'
{
  "log": {
    "loglevel": "info"
  },

  "dns": {
    "servers": [
      "1.1.1.1",
      "8.8.8.8"
    ],
    "queryStrategy": "UseIPv4"
  },

  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "rproxy2"
        ],
        "outboundTag": "home-socks"
      }
    ]
  },

  "outbounds": [
    {
      "tag": "home-socks",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 1080
          }
        ]
      }
    },

    {
      "tag": "proxy",
      "protocol": "vless",

      "settings": {
        "address": "188.72.103.3",
        "port": 443,
        "id": "2d323496-66e9-432a-8806-60bd2ec5e005",
        "encryption": "none",

        "reverse": {
          "tag": "rproxy2"
        }
      },

      "streamSettings": {
        "network": "xhttp",
        "security": "tls",

        "tlsSettings": {
          "serverName": "cdn.kittydumper.ru",
          "fingerprint": "firefox",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },

        "xhttpSettings": {
          "mode": "packet-up",
          "path": "/api/uploadFile/",

          "extra": {
            "path": "/api/uploadFile/",

            "xmux": {
              "cMaxLifetimeMs": 300000,
              "cMaxReuseTimes": 100,
              "maxConcurrency": "16-32",
              "maxConnections": 0
            },

            "seqKey": "chunk_id",
            "sessionKey": "X-Upload-Token",

            "xPaddingKey": "hash",
            "seqPlacement": "query",

            "sessionIDKey": "X-Upload-Token",
            "sessionIDTable": "Base62",

            "xPaddingHeader": "X-Client-Version",
            "xPaddingMethod": "tokenish",

            "sessionIDLength": "16-32",

            "sessionPlacement": "header",
            "sessionIDPlacement": "header",

            "uplinkHTTPMethod": "GET",

            "xPaddingObfsMode": true,
            "xPaddingPlacement": "queryInHeader"
          },

          "noSSEHeader": false
        }
      }
    }
  ]
}
EOF


echo "[+] Starting local SOCKS..."

nohup ./xray run -c socks.json > socks.log 2>&1 &


sleep 2


echo "[+] Starting reverse bridge..."

nohup ./xray run -c reverse.json > reverse.log 2>&1 &


sleep 5


COUNT=$(pgrep -fc "xray run")


if [ "$COUNT" -ge 2 ]; then

    echo
    echo '$$$ 1000$ dollars raskur activated $$$'
    echo

    echo "Xray processes:"
    ps -A | grep xray

    echo
    echo "Logs:"
    echo "tail -f ~/xray/reverse.log"

else

    echo
    echo "[!] Xray failed to start"
    echo

    echo "SOCKS LOG:"
    cat socks.log 2>/dev/null || true

    echo
    echo "REVERSE LOG:"
    cat reverse.log 2>/dev/null || true
fi
