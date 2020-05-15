Edit transformation/src/virtualsensors.c  

Make: 
```
$ cd transformation/make
$ make -f Makefile.x64Linux3gcc5.4.0
```
Build

```
$ docker build -t rtiroutingservice_vsensortemplate .
```

run:
```
$ docker run -it --env TOPIC_INPUT="Example TemperatureSensor Topic" --env TOPIC_OUTPUT="Topic1" rtiroutingservice_vsensortemplate
```
