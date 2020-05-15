library(SPARQL)
library(tidyr)

## This script contains code for getting node capabilites from stardog
## outout will be in system_capabilities, close FCA format, only one column will contain nodenames
#     _   __          __                               __    _ ___ __  _
#    / | / /___  ____/ /__     _________ _____  ____ _/ /_  (_) (_) /_(_)__  _____
#   /  |/ / __ \/ __  / _ \   / ___/ __ `/ __ \/ __ `/ __ \/ / / / __/ / _ \/ ___/
#  / /|  / /_/ / /_/ /  __/  / /__/ /_/ / /_/ / /_/ / /_/ / / / / /_/ /  __(__  )
# /_/ |_/\____/\__,_/\___/   \___/\__,_/ .___/\__,_/_.___/_/_/_/\__/_/\___/____/
#                                     /_/

endpoint <- "http://localhost:30820/cpsds/query"

prefix <- c("dds","http://inf.mit.bme.hu/research/dds/",
            "sosa","http://www.w3.org/ns/sosa/",
            "cpsds","http://inf.mit.bme.hu/research/cpsds/",
            "ssn","http://www.w3.org/ns/ssn/>",
            "k8s","http://inf.mit.bme.hu/research/kubernetes/")

# Create query statement
query <-
"SELECT * { 
?nodes rdf:type k8s:Kubernetes_Node.                #gettings Kubernetes nodes
?nodes ssn:hasSubSystem ?sensors.                   #getting it's sensors
?sensors cpsds:has_Location ?locations.             #Sensor location
?sensors ssn:implements ?proc.                      #get procedures for sensors
?locations cpsds:has_Location ?loc_hierarchy.       #Location hierarhcy
?sensors systems:hasSystemCapability ?systemcap.    #Sensor capability
?systemcap systems:hasSystemProperty ?systemprop.   #sensor capability's property
?systemprop rdf:type cpsds:Unit.                    #Property for Unit
}
"

# Use SPARQL package to submit query and save results to a data frame
query_result <- SPARQL(endpoint,query, ns=prefix, curl_args=list(userpwd="admin:admin"), extra=list(reasoning="TRUE"))

# Converting "long" dataformat to "wide"
query_result$results$flatten_helper=1
query_result_wide <- spread(query_result$results,"proc","flatten_helper")

query_result_wide$flatten_helper=1
query_result_wide <- spread(query_result_wide,"systemprop","flatten_helper")

query_result_wide$flatten_helper=1
query_result_wide <- spread(query_result_wide,"loc_hierarchy","flatten_helper")

# First column to "names", and 1-0 filling for FCA
system_capabilities<-query_result_wide[,2:ncol(query_result_wide)]

system_capabilities[!is.na(system_capabilities)] <- 1
system_capabilities[is.na(system_capabilities)] <- 0

system_capabilities <- system_capabilities[,4:ncol(system_capabilities)]
system_capabilities$names = query_result_wide[,1]




