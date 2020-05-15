library(fcaR)
library(SPARQL)
library(tidyr)

### searching for suitable vsensor the fulfil topic requirements

endpoint <- "http://localhost:30820/cpsds/query"
prefix <- c("dds","http://inf.mit.bme.hu/research/dds/",
            "sosa","http://www.w3.org/ns/sosa/",
            "cpsds","http://inf.mit.bme.hu/research/cpsds/",
            "ssn","http://www.w3.org/ns/ssn/>",
            "k8s","http://inf.mit.bme.hu/research/kubernetes/")

getSensorSubstitutabilities <- function(SystemCapabilityIntents,GapToFill){
  
query <-
  paste("SELECT * { 
    ?vsensorid cpsds:has_Virtual_Sensor_Output",GapToFill,".
    ?vsensorid cpsds:hasVirtualSensorInput ?vsensorinput.
    ?vsensorid cpsds:has_Virtual_Sensor_Output ?vsensoroutput.
    ?vsensorid cpsds:DockerImageName ?dockerimagename.
}")

query_results_v <- SPARQL(endpoint,query, ns=prefix, curl_args=list(userpwd="admin:admin"), extra=list(reasoning="TRUE"))


if(length(query_results_v$results) ==0 ){
   return(NA)
}else{


#Mivel lehet helyettesíteni a hiányosságot?
is.element(query_results_v$results$vsensorinput,SystemCapabilityIntents)
idx <- match(query_results_v$results$vsensorinput,SystemCapabilityIntents)
if( !is.na(idx) && !is.null(SystemCapabilityIntents[idx]) ){
  Input <- Filter(Negate(is.null), SystemCapabilityIntents[idx])
}

mydf <- as.data.frame(Input, col.names="Input")

idy <- match(Input,query_results_v$results$vsensorinput)
mydf <- cbind(VSensorID = as.character(query_results_v$results$vsensorid[idy]),Input=mydf,Output=as.character(GapToFill),
              DockerImageName=as.character(query_results_v$results$dockerimagename[idy]))


row.has.na <- apply(mydf, 1, function(x){any(is.na(x))})
mydf <- mydf[!row.has.na,]
}
}
# topicgaps <- listOfTopicReqGaps[[1]]
# bb2_gaps <- topicgaps[[2]]
# 
# VSensorsToFillGap <- getSensorSubstitutabilities(unlist(listOfSystemIntents[2]),bb2_gaps)
# VSensorsToFillGap


# query <-
#   paste("SELECT * { 
#     ?vsensorid cpsds:has_Virtual_Sensor_Output",bb2_gaps,".
#     ?vsensorid cpsds:hasVirtualSensorInput ?vsensorinput.
#     ?vsensorid cpsds:has_Virtual_Sensor_Output ?vsensoroutput.
# }")
# 
# query_results_v <- SPARQL(endpoint,query, ns=prefix, curl_args=list(userpwd="admin:admin"), extra=list(reasoning="TRUE"))
