FROM timberio/vector:0.60.0-debian@sha256:3ccb4bbd36e38734394e158db1411e91a69d076ed25013f8de385046a382d36a as logshipper

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
