FROM timberio/vector:0.56.0-debian@sha256:93b072b416fd29152f1bfe5bd2925a0b48999aeb069f3ae000691f82a135c200 as logshipper

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
