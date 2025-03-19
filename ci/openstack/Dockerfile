FROM python:3.11-alpine3.21
MAINTAINER "samuel.antao@amd.com"

RUN set -eux ; \
  apk update ; \
  apk add gcc python3-dev  musl-dev linux-headers ; \
  apk cache clean 
  
RUN set -eux ; \
  pip install \
    python-openstackclient==4.0.2 \
    python-cinderclient==5.0.2 \
    python-glanceclient==2.17.1 \
    python-heatclient==1.18.1 \
    python-keystoneclient==3.21.0 \
    python-neutronclient==6.14.1 \
    python-novaclient==15.1.1 \
    python-swiftclient==3.8.1

RUN set -eux ; \
  sed -i 's/from oslo_utils //g' /usr/local/lib/python3.11/site-packages/heatclient/common/hook_utils.py


FROM python:3.11-alpine3.21
MAINTAINER "samuel.antao@amd.com"

RUN set -eux ; \
  apk update ; \
  apk add curl openssh-client ; \
  apk cache clean 

COPY --from=0 /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=0 /usr/local/bin /usr/local/bin

ENTRYPOINT ["openstack"]
