upstream hunchentoot {
  server 127.0.0.1:8000;
}

server {
  listen 80;
  server_name cutlass.ru;

  rewrite ^(.*)/$ $1/home.html;

  location / {
    root /var/www/cutlass.ru/public/;

    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $host;

    if (!-f $request_filename) {
      rewrite ^/(.*)$ /cutlass.ru/$1 last;
      break;
    }
  }

  location /cutlass.ru/ {
    proxy_pass http://hunchentoot;
  }
}
