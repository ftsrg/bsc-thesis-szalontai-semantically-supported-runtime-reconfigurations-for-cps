FROM rtiroutingservice

WORKDIR /rti

COPY topic_bridge_w_custom_transf.xml ./
COPY /transformation/libvirtualsensors.so ./
COPY start.sh ./
RUN chmod +x ./start.sh

ENTRYPOINT ["./start.sh"]
