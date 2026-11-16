FROM timberio/vector:0.62.0-debian@sha256:6266b1d35c844918ff1c48ea2ec4f57c2b0664c46f3e17fc2418d5dda1692068 as logshipper

# ca-certificates is listed to pull security fixes newer than the base image.
RUN apt update \
    && apt install -y \
    ca-certificates \
    gettext \
    && rm -rf /var/cache/apt

RUN rm -rf /etc/vector \
    && mkdir -p /etc/vector/certificates

COPY vector.yaml /etc/vector/
COPY templates/ /etc/vector/templates/
COPY start.sh .

ENV LOG warn
ENV DISABLE false

ENTRYPOINT [ "/bin/bash" ]

CMD [ "start.sh" ]
