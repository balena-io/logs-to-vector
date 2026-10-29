FROM timberio/vector:0.61.0-debian@sha256:f6c23b5a7e16fb2838d33619ef7acf4bad2289a7cf22bc90efc2371f520c4ea2 as logshipper

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
