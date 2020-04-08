FROM ubuntu

RUN apt-get update \
    && apt-get install postgresql postgresql-client postgresql-contrib -y

ENV PORT=5432
ENV VERSION=10

#should define outside of this image
ENV CLUSTER='Y'
ENV IS_SLAVE='Y'

ENV CONFIG_PATH=/etc/postgresql/${VERSION}/main

RUN mkdir -p /var/lib/${VERSION}/main/archive/

COPY entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh

USER postgres

#Create User/Role
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER replica REPLICATION LOGIN ENCRYPTED PASSWORD 'replicauser@';" && \
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" && \
    createdb -O docker docker

#Listener config
RUN echo "listen_addresses='*'" >> ${CONFIG_PATH}/postgresql.conf

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/${VERSION}/main/pg_hba.conf


#Execute script if clustering
RUN /usr/bin/entrypoint.sh


EXPOSE ${PORT}

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]


#COPY entrypoint.sh /usr/bin
#RUN chmod +x /usr/bin/entrypoint.sh
#ENTRYPOINT /usr/bin/entrypoint.sh

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/10/bin/postgres", "-D", "/var/lib/postgresql/10/main", "-c", "config_file=/etc/postgresql/10/main/postgresql.conf"]
