
FROM ubuntu:latest


RUN apt-get update && apt-get install -y \
    netcat-openbsd


WORKDIR /app


RUN echo '#!/bin/bash\nwhile true; do echo -e "HTTP/1.1 200 OK\n\nNamaste from Docker" | nc -l -p 8080 -q 1; done' > /app/hello.sh && chmod +x /app/hello.sh


EXPOSE 8080


CMD ["/app/hello.sh"]
