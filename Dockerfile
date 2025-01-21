FROM timberio/vector:0.44.0-debian as logshipper

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
