#!/bin/sh

BIN=/opt/bin

mkdir -p $BIN

cat <<EOF > ${BIN}/wocker-multi
#!/bin/sh

NAME=\$1
DOMAIN=\${2:="test"}

ID=\$(docker ps -q -a -f name=\${NAME})
if [ -z "\${ID}" ]; then
  wocker run --name \${NAME}
else
  wocker start \${NAME}
fi

until docker exec -u wocker \${NAME} wp option update siteurl http://\${NAME}.wocker.\${DOMAIN} 2>/dev/null; do
  usleep 500
done
docker exec -u wocker \${NAME} wp option update home http://\${NAME}.wocker.\${DOMAIN}
EOF

chmod +x ${BIN}/wocker-multi
