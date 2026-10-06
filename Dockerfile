FROM timberio/vector:0.59.0-debian@sha256:98e7b4dfe50750e61470697bbd2fbeca643d12bea97f351005038ef506eab630 as logshipper

RUN apt update \
    && apt install -y \
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
