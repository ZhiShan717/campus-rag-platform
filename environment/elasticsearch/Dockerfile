ARG ELASTIC_VERSION=8.11.4
FROM docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}
ARG ELASTIC_VERSION
# Official IK maintainer installation method; the version must exactly match ES.
# Source: https://github.com/infinilabs/analysis-ik#how-to-install
RUN bin/elasticsearch-plugin install --batch "https://get.infini.cloud/elasticsearch/analysis-ik/${ELASTIC_VERSION}"
