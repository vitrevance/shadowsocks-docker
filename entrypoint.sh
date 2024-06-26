#!/bin/bash

if [[ -z "${PASSWORD}" ]]; then
  export PASSWORD="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo "Password" ${PASSWORD}

export PASSWORD_JSON="$(echo -n "$PASSWORD" | jq -Rc)"

if [[ -z "${ENCRYPT}" ]]; then
  export ENCRYPT="chacha20-ietf-poly1305"
fi

if [[ -z "${V2_Path}" ]]; then
  export V2_Path="s233"
fi
export V2_Path="${V2_Path}_${PASSWORD}"
echo "V2 Path" ${V2_Path}

if [[ -z "${QR_Path}" ]]; then
  export QR_Path="/qr_img"
fi
export QR_Path="${QR_Path}_${PASSWORD}"
echo "QR Path" ${QR_Path}

if [[ -z "${DOMAIN}" ]]; then
  echo "Domain variable is required!"
fi
echo "Domain " ${DOMAIN}

bash /conf/shadowsocks-libev_config.json >  /etc/shadowsocks-libev/config.json
echo /etc/shadowsocks-libev/config.json
cat /etc/shadowsocks-libev/config.json

bash /conf/nginx_ss.conf > /etc/nginx/conf.d/ss.conf
echo /etc/nginx/conf.d/ss.conf
cat /etc/nginx/conf.d/ss.conf


if [ "$GenQR" = "no" ]; then
  echo "Do not generate QR-code"
else
  [ ! -d /wwwroot/${QR_Path} ] && mkdir /wwwroot/${QR_Path}
  plugin=$(echo -n "v2ray;path=/${V2_Path};host=${DOMAIN};tls" | sed -e 's/\//%2F/g' -e 's/=/%3D/g' -e 's/;/%3B/g')
  ss="ss://$(echo -n ${ENCRYPT}:${PASSWORD} | base64 -w 0)@${DOMAIN}:443?plugin=${plugin}" 
  echo "${ss}" | tr -d '\n' > /wwwroot/${QR_Path}/index.html
  echo -n "${ss}" | qrencode -s 6 -o /wwwroot/${QR_Path}/vpn.png
fi

ss-server -c /etc/shadowsocks-libev/config.json
rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'
