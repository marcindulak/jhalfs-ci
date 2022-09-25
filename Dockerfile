FROM ubuntu:latest

# Install dependencies mentioned in jhalfs README 2. PREREQUISITIES
RUN apt-get update \
    && apt-get install -y wget sudo libxml2 libxslt-dev docbook-xml docbook-xsl-nons \
    && rm -rf /var/lib/apt/lists/*