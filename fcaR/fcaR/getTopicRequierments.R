library(SPARQL)
library(tidyr)


## This script get's topic requirements from stardog, and convert to close FCA format
## output: topic_requierments

#  _____           _        ____                  _                               _
# |_   _|__  _ __ (_) ___  |  _ \ ___  __ _ _   _(_)_ __ ___ _ __ ___   ___ _ __ | |_ ___
#   | |/ _ \| '_ \| |/ __| | |_) / _ \/ _` | | | | | '__/ _ \ '_ ` _ \ / _ \ '_ \| __/ __|
#   | | (_) | |_) | | (__  |  _ <  __/ (_| | |_| | | | |  __/ | | | | |  __/ | | | |_\__ \
#   |_|\___/| .__/|_|\___| |_| \_\___|\__, |\__,_|_|_|  \___|_| |_| |_|\___|_| |_|\__|___/
#           |_|                          |_|
                                         
endpoint <- "http://localhost:30820/cpsds/query"
prefix <- c("dds","http://inf.mit.bme.hu/research/dds/",
            "sosa","http://www.w3.org/ns/sosa/",
            "cpsds","http://inf.mit.bme.hu/research/cpsds/",
            "ssn","http://www.w3.org/ns/ssn/>",
            "k8s","http://inf.mit.bme.hu/research/kubernetes/")

# create query statement
query <-
  "SELECT * { 
?observations rdf:type sosa:Observation.                              #Get all observations
?observations sosa:usedProcedure ?proc.                               #Get observation's procedures
?observations sosa:observedProperty ?observableProperty.              #Get observation's ObservableProperties
?observableProperty sosa:hasFeatureOfInterest ?foilocations.          #Get ObservablePropertiy Locations
?observableProperty ssn:isPropertyOf ?topics.                         #Get ObservableProperty Topics
?topics rdf:type dds:Topic.                                           #Filter only dds:Topic
?foilocations cpsds:has_Location ?loc_hierarchy.                      #Get Location hierarchy
?observableProperty cpsds:needs_system_capability ?systemcapability.  #Get ObservableProperty System capability requirements
?systemcapability systems:hasSystemProperty ?systemproperty.          #Get System capability's property
?systemproperty rdf:type cpsds:Unit.                                  #Get Unit
}
"

# Use SPARQL package to submit query and save results to a data frame
query_results_t <- SPARQL(endpoint,query, ns=prefix, curl_args=list(userpwd="admin:admin"), extra=list(reasoning="TRUE"))

# Converting "long" dataformat to "wide"
query_results_t$results$flatten_helper=1
query_results_t_wide <- spread(query_results_t$results,"proc","flatten_helper")

query_results_t_wide$flatten_helper=1
query_results_t_wide <- tidyr::spread(query_results_t_wide,"systemproperty","flatten_helper")

query_results_t_wide$flatten_helper=1
query_results_t_wide <- tidyr::spread(query_results_t_wide,"loc_hierarchy","flatten_helper")

# Topic column to "names", and 1-0 filling for FCA
query_results_t_wide2 <- query_results_t_wide [,4:ncol(query_results_t_wide )]
topic_requierments <- query_results_t_wide2[,2:ncol(query_results_t_wide2)]

topic_requierments[!is.na(topic_requierments)] <- 1
topic_requierments[ is.na(topic_requierments)] <- 0

topic_requierments <- topic_requierments[,2:ncol(topic_requierments)]

topic_requierments$names = query_results_t_wide2[,1]


 




