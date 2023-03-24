FROM ubuntu:20.04
ENV LANG C.UTF-8
ARG PROJECT=project
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y

RUN apt install -y sudo \
        && apt install -y tzdata \
        && ln -fs /usr/share/zoneinfo/America/Lima /etc/localtime \
        && dpkg-reconfigure --frontend noninteractive tzdata \
        && apt install nano -y \
        && apt install ack -y \
        && apt install wget -y \
        && apt install python3 -y \
        && apt install python3-pip -y \
        && apt install tar -y \
        && pip3 install num2words xlwt

RUN wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
RUN echo "deb http://nightly.odoo.com/14.0/nightly/deb/ ./" >> /etc/apt/sources.list.d/odoo.list
RUN apt update && apt-get install odoo -y
RUN apt update && apt upgrade odoo -y

# RUN echo "deb http://neurodebian.ovgu.de/debian/ bionic main contrib non-free" >> /etc/apt/sources.list
# RUN apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9
# RUN apt update && apt-get install python3-xlwt -y

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
RUN tar -xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
RUN rm -f /usr/local/bin/wkht* \
        && rm -f /usr/bin/wkht* \
        && cp -r wkhtmltox/bin/* /usr/local/bin/ \
        && cp -r wkhtmltox/bin/* /usr/bin/ 

# RUN apt update -y && apt install -y libssl1.0-dev

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main 13' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /
COPY ./requirements.txt /

RUN mkdir -p /mnt/${PROJECT} \
        && chown -R odoo /mnt/${PROJECT}
RUN mkdir -p /mnt/${PROJECT}_utils \
        && chown -R odoo /mnt/${PROJECT}_utils
VOLUME ["${PROJECT}", "/mnt/${PROJECT}"]

RUN pip3 install -r requirements.txt
RUN adduser --system --home=/opt/odoo --group odoo

EXPOSE 8069

USER odoo
ENTRYPOINT ["/entrypoint.sh"]
# CMD ["odoo", "-c/etc/odoo/odoo.conf"]
CMD ["bash"]
