set -x
cd editor
npm ci
npm run build
zip editor.zip dist/*
scp editor.zip root@10.0.0.10:/tmp/editor.zip
ssh root@10.0.0.10 "set -x && cd /tmp && unzip -u editor.zip && cd dist && rm -r /var/www/html/editor/* && cp -r * /var/www/html/editor && chown -R www-data:www-data /var/www/html/editor"
