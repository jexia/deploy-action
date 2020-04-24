FROM python:3-slim

RUN pip3 install 'jexia-cli==1.0' --quiet

COPY deploy.sh /deploy.sh

ENTRYPOINT ["/deploy.sh"]