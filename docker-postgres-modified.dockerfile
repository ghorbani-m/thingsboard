#
# Copyright © 2016-2024 The Thingsboard Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM thingsboard/openjdk17:bookworm-slim

ENV PG_MAJOR 12

ENV DATA_FOLDER=/data

ENV HTTP_BIND_PORT=9090
ENV DATABASE_TS_TYPE=sql

ENV PGDATA=/data/db
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

ENV SPRING_DRIVER_CLASS_NAME=org.postgresql.Driver
ENV SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/thingsboard
ENV SPRING_DATASOURCE_USERNAME=thingsboard
ENV SPRING_DATASOURCE_PASSWORD=postgres

ENV PGLOG=/var/log/postgres

COPY logback.xml thingsboard.conf start-db.sh stop-db.sh start-tb.sh upgrade-tb.sh install-tb.sh thingsboard.deb /tmp/

RUN apt-get update \
    && apt-get install -y --no-install-recommends wget gnupg2 \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(. /etc/os-release && echo -n $VERSION_CODENAME)-pgdg main" | tee --append /etc/apt/sources.list.d/pgdg.list > /dev/null \
    && wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O- | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/* \
    && update-rc.d postgresql disable \
    && apt-get purge -y --auto-remove \
    && chmod a+x /tmp/*.sh \
    && mv /tmp/start-tb.sh /usr/bin \
    && mv /tmp/upgrade-tb.sh /usr/bin \
    && mv /tmp/install-tb.sh /usr/bin \
    && mv /tmp/start-db.sh /usr/bin \
    && mv /tmp/stop-db.sh /usr/bin \
    && dpkg -i /tmp/thingsboard.deb \
    && rm /tmp/thingsboard.deb \
    && (systemctl --no-reload disable --now thingsboard.service > /dev/null 2>&1 || :) \
    && mv /tmp/logback.xml /usr/share/thingsboard/conf \
    && mv /tmp/thingsboard.conf /usr/share/thingsboard/conf \
    && mkdir -p $PGLOG \
    && chown -R thingsboard:thingsboard $PGLOG \
    && chown -R thingsboard:thingsboard /var/run/postgresql \
    && mkdir -p /data \
    && chown -R thingsboard:thingsboard /data \
    && chown -R thingsboard:thingsboard /var/log/thingsboard \
    && chmod 555 /usr/share/thingsboard/bin/thingsboard.jar

USER thingsboard

EXPOSE 9090
EXPOSE 1883
EXPOSE 5683/udp
EXPOSE 5685/udp
EXPOSE 5686/udp

VOLUME ["/data"]

CMD ["start-tb.sh"] 