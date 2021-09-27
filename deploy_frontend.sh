set -x
zip frontend.zip frontend/*
scp frontend.zip root@10.0.0.10:/tmp/frontend.zip
ssh root@10.0.0.10 "set -x && cd /tmp && unzip -u frontend.zip && cd frontend && rm -r /var/www/html/frontend/* && cp -r * /var/www/html/frontend && chown -R www-data:www-data /var/www/html/frontend"
