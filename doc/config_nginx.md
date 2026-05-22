sudo nano /etc/nginx/sites-available/mcp
server {
    server_name mcp.hnhdecor.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;

        # Cấu hình Header cơ bản
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Explicitly forward Authorization header
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;

        # RẤT QUAN TRỌNG CHO MCP / SSE (Server-Sent Events) / HTTP Streaming:
        proxy_set_header Connection "keep-alive";
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding on;
        proxy_read_timeout 86400; # Giữ connection không bị ngắt giữa chừng
    }

    # BẮT ĐẦU: Phần Certbot tự sinh (GIỮ NGUYÊN)
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/efms.hnhdecor.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/efms.hnhdecor.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    # KẾT THÚC: Phần Certbot tự sinh
}

server {
    if ($host = mcp.hnhdecor.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name mcp.hnhdecor.com;
    listen 80;
    return 404; # managed by Certbot
}

sudo nano /etc/nginx/sites-available/api
server {
    server_name api.hnhdecor.com;

    location / {
        proxy_pass http://localhost:8080;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

sudo ln -s /etc/nginx/sites-available/portainer /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/mcp /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/api /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl restart nginx

sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx