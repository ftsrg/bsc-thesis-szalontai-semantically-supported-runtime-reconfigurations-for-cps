library("rlist")
library("crayon")
library("stringi")

GIROOT <- "D:/Dokumentumok/szakdoga/"
GITROOTWSL <- "/d/Dokumentumok/szakdoga/"



## This file contains code for kubernetes labeling
## Kubernetes fca.topic-schedulable and fca.pref labels
## and also for generating configmaps and pod configs

###
## Split element by delim ":", and return first part
## Args: element, string "cpsds:BB1"
## islower: optional, convert to lowercase
## example Input "cpsds:Beaglebone1" output "cpsds"
#
getSplittedPre <- function(element,islower){
  myelement <- strsplit(element,":")[[1]]
  splittedelementPre <- myelement[[1]]
  
  if(!missing(islower) && islower){
    splittedelementPre <- stri_trans_tolower(splittedelementPre)
  }else{
    return(splittedelementPre)
  }
}

###
## Split element by delim ":", and return the last part
## Args: element, string "cpsds:BB1"
## islower: optional, convert to lowercase
## example Input "cpsds:Beaglebone1" output "beaglebone1"
#
getSplittedPost <- function(element,islower){
  myelement <- strsplit(element,":")[[1]]
  splittedelementPost <- myelement[[2]]
  
  if(!missing(islower) && islower){
    splittedelementPost <- stri_trans_tolower(splittedelementPost)
  }else{
    return(splittedelementPost)
  }
}

###
## Create Kubernetes config map file
## Body is predefined
## Args: element - configmap name
## filepath - output file
## example createConfigMap("cpsds:BB1","GITROOT/kubernetes/configmap")
#
createConfigMap <- function(element, filepath ){
  splittedPre <- getSplittedPre(element,TRUE)
  splittedPost <- getSplittedPost(element,TRUE)
  name <- splittedPre %+% "." %+% splittedPost
    
  name <- str_replace_all(name,"_","-")
  header <- "apiVersion: v1
kind: ConfigMap
metadata:
  name: " %+% name %+% "
  namespace: default
data:
  NDDS_DISCOVERY_PEERS: rtps@rti-cloud-discovery.default:7400"
  write(header,file=filepath)
}
  
###
## Create Kubernetes pod file for routingservice
## Body is predefined
## Args: element - pod name
## rsConfmap, configMapRef name, should be contain topic information
## filepath - output file
## example createConfigMap("cpsds:BB1","GITROOT/kubernetes/configmap")
#
createRSPod <- function(element, rsConfmap,filepath){
  
  splittedPre <- getSplittedPre(element,TRUE)
splittedPost <- getSplittedPost(element,TRUE)
name <- str_replace_all(splittedPre,"_","-")


  header <- "apiVersion: v1
kind: Pod
metadata:
  name: " %+% name %+%  "
  labels:
    app: " %+% splittedPre %+% "
spec:
  containers:
  - name: " %+% name %+% "
    image: " %+% splittedPre %+% ":" %+% splittedPost %+% " 
    envFrom:
    - configMapRef:
        name: " %+% rsConfmap %+% "
    ports:
      - containerPort: 7400
      - containerPort: 7410
      - containerPort: 7411
      - containerPort: 7412
      - containerPort: 7413
      - containerPort: 7414
      - containerPort: 7415
      - containerPort: 7416
      - containerPort: 7417
      - containerPort: 7418
    "
  write(header,file=filepath,append = FALSE)
}

###
## Create a filepath
## Args: currentNodeName - node name, it will be a folder
## splittedPre - first part of the file, should be ontology prefix
## splittedPost - second part of file, usually topic name
## Output - filepath
#
createMyFilepath <- function(currentNodeName,splittedPre,splittedPost, folder){
  if(missing(folder)){
    myfilepath <- GIROOT %+% "kubernetes/configmaps/"%+% currentNodeName %+% "/" %+% splittedPre %+% "_" %+% splittedPost %+% ".yml"
  }else{
    myfilepath <- GIROOT %+% "kubernetes/"%+% folder %+% "/" %+% currentNodeName %+% "/" %+% splittedPre %+% "_" %+% splittedPost %+% ".yml"
  }
}

###
## Rename Nodes
## Args: currentNodeName - node name, it will be a folder
## splittedPre - first part of the file, should be ontology prefix
## splittedPost - second part of file, usually topic name
## Output - filepath
#
renameNodes <- function(NodeName){
  myNode = "";
  #maps to my WSL
  if(NodeName == "BeagleBone1" || NodeName == "beaglebone1"){
    myNode= "kind-worker"
  }else if(NodeName == "BeagleBone2"|| NodeName == "beaglebone2"){
    myNode= "kind-worker2"
  }else if(NodeName == "BeagleBone3" || NodeName == "beaglebone3"){
    myNode= "kind-worker3"
  }
}

###
## Kubernetes label on nodes
#
labelMyNode <- function(myNode,label){
  runcontainer= "docker run --rm  -v " %+% GITROOTWSL %+% "kubeconfig:/.kube/config  --network=host bitnami/kubectl:latest"
  cmd  <- runcontainer %+% " label node " %+% myNode %+% " " %+% label
  system(cmd)
  print(cmd)
}

#__      __    __   ___                         __
#\ \    / /   / /  / _ \   _ _ ___ __ ___ _ _  / _|
# \ \/\/ /   / /  | (_) | | '_/ -_) _/ _ \ ' \|  _|
#  \_/\_/   /_/    \___/  |_| \___\__\___/_||_|_|
  
###
# Topic schedulable without reconfiguration -> Topic_schedulable label
# input: listOfTopicReqGaps the Topic->Node value is 0, indicating there is 0 gaps to fulfill topic requirements
# output: k8sLabel_TopicSchedulableOnNode, [list of Nodes]-> [list of fulfillable topics without reconfiguration]

k8sLabel_TopicSchedulableOnNode <- list()
# Get node names
nodeNamesdf<- subset(system_capabilities, select = c("names"))
for(i in 1:nrow(system_capabilities)){
  k8sLabel_TopicSchedulableOnNode[[nodeNamesdf$names[i]]] <- list()
}

# append topic to node if its fulfill topic reqs without reconfiguration
for(k in 1:nrow(topic_requierments)){
  for(i in 1:nrow(system_capabilities)){
    perTopic <- listOfTopicReqGaps[[k]]
    perTopicName <- names(listOfTopicReqGaps)
    perSystem <- perTopic[[i]]
    
    if(length(perSystem) == 0){
      k8sLabel_TopicSchedulableOnNode[[i]] <- list.append(k8sLabel_TopicSchedulableOnNode[[i]],perTopicName[[k]])
    }
  }
}


for(i in 1:length(k8sLabel_TopicSchedulableOnNode)){  # i for node iter
    topicCountperNode <- length(k8sLabel_TopicSchedulableOnNode[[i]])
    if(topicCountperNode>0){
      for(j in 1:length(k8sLabel_TopicSchedulableOnNode[[i]]) ){
        perNode <- k8sLabel_TopicSchedulableOnNode[[i]]
        perNodeName <- names(k8sLabel_TopicSchedulableOnNode)
        perTopic <- perNode[[j]]
        
       create_TopicSchedulableLabel(perNodeName[i],perTopic)
       create_fcaPrefLabel(perNodeName[i],perTopic)
      }
    }
}

###
## create the label for "fca.topic-schedulable"
## output label on kubernetes node - "fca.topic-schedulable/cpsds.topic1 = TRUE" 
#
create_TopicSchedulableLabel <- function(Node,perTopic){
  #kubectl label node <node-name> <label-key>=<label-value>
  # a valid label must be an empty string or consist of alphanumeric characters, '-', '_' or '.', 
  #and must start and end with an alphanumeric character (e.g. 'MyValue',  or 'my_value',  or '12345', 
  #regex used for validation is '(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?')
  
  splittedNodePost <- getSplittedPost(Node)
  splittedTopicPre <- getSplittedPre(perTopic,TRUE)
  splittedTopicPost <- getSplittedPost(perTopic,TRUE)
  myNode <- renameNodes(splittedNodePost)
  
  mylabel <- "fca.topic-schedulable/" %+% splittedTopicPre %+% "." %+% splittedTopicPost %+%"=TRUE" 
  labelMyNode(myNode, mylabel)
  
  myfilepath <- createMyFilepath(myNode,splittedTopicPre,splittedNodePost)
  
  if(!file.exists(myfilepath)){
    createConfigMap(perTopic,myfilepath)
  }
  
  mystring <- "  TOPIC_OUTPUT: " %+%splittedTopicPost
  print(myfilepath)
  write(mystring,file=myfilepath,append=TRUE)
   
}

###
## create the label for "fca.pref"
## output label on kubernetes node - "fca.pref/cpsds.topic1 = TRUE" 
#
create_fcaPrefLabel <- function(Node,perTopic){
  #kubectl label node <node-name> <label-key>=<label-value>
  # a valid label must be an empty string or consist of alphanumeric characters, '-', '_' or '.', 
  #and must start and end with an alphanumeric character (e.g. 'MyValue',  or 'my_value',  or '12345', 
  #regex used for validation is '(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?')
  
  splittedNodePost <- getSplittedPost(Node)
  splittedTopicPre <- getSplittedPre(perTopic,TRUE)
  splittedTopicPost <- getSplittedPost(perTopic,TRUE)
  myNode <- renameNodes(splittedNodePost)
  
  mylabel <- "fca.pref/" %+% splittedTopicPre %+% "." %+% splittedTopicPost %+%"=TRUE" 
  labelMyNode(myNode, mylabel)
}

#                               ____
#   ________  _________  ____  / __/
#  / ___/ _ \/ ___/ __ \/ __ \/ /_
# / /  /  __/ /__/ /_/ / / / / __/
#/_/   \___/\___/\____/_/ /_/_/

## ha van reconf item, akkor configmap outputot a podhoz átállítani  topic{n}_tovsensor
## létrehozni a reconf confmapot
## ha egy reconf item van, akkor a (topic{n}) output, topic{n}_tovsensor input
## ha egynél több, akkor  reconf[i].input = reconf[i-1].output; reconf[i].output = topic{n}_tovsensor{i}
## utolsónál pedig a topic{n} az output

## ha van helyettesíthető lehetőség, le kell generálni az eredeti podhoz tartozó konfig mappot, átirányított topikkal.
## fel kell labelelezni az azonos nodeot, topic schedulablelel
## fel kell labelelezni, RECONF_NEED taggel
## le kell generálni a szükséges deploymenthez tartozó konfig mappokat


for(k in 1:nrow(topic_requierments)){
  for(i in 1:nrow(system_capabilities)){
    perTopic <- ReconfigDeployments[[k]]
    perTopicName <- names(ReconfigDeployments)
    nodeNames <- names(ReconfigDeployments[[k]])
    pervsensor <- perTopic[[i]]
    
    ## melyik topickhoz van helyettesíthető lehetőség?
  
    if(!is.na(pervsensor)){
      
      ## ha van helyettesíthető lehetőség, le kell generálni az eredeti podhoz tartozó konfig mappot, átirányított topikkal.
        
        splittedTopicPre <- getSplittedPre(perTopicName[[k]],TRUE)
        splittedTopicPost <- getSplittedPost(perTopicName[[k]],TRUE)
        currentNodeName <- renameNodes(getSplittedPost(nodeNames[[i]],TRUE))
        
        ## ha van, akkor át kell irányítani a router bemenetére, ami fix {alma}_raw
        myfilepath <- createMyFilepath(currentNodeName, splittedTopicPre, splittedTopicPost)
         
        print(myfilepath)
         
        createConfigMap(perTopicName[[k]],myfilepath)
        mystring <- "  TOPIC_OUTPUT: " %+%splittedTopicPost %+% "_raw"
        
        write(mystring,file=myfilepath,append=TRUE)
      
      ######################
      ## fel kell labelelezni az azonos nodeot, topic schedulablelel
          
        mylabel <- "fca.topic-schedulable/" %+% splittedTopicPre %+% "." %+% splittedTopicPost %+%"=TRUE" 
        labelMyNode(currentNodeName,mylabel)
          
      ## fel kell labelelezni, RECONF_NEED taggel
        
        myreconflabel <- "fca.need-reconf/" %+% splittedTopicPre %+% "." %+% splittedTopicPost %+%"=TRUE" 
        labelMyNode(currentNodeName,myreconflabel)
      
      ## le kell generálni a szükséges deploymenthez tartozó konfig mappokat
      ## TODO mivan ha több reconf kell hogy menjen
        if(nrow(pervsensor) == 1){
          
          currentDockerImage <- as.character(pervsensor$DockerImageName[[1]])
        
          routingservicePre <- getSplittedPre(currentDockerImage)
          routingservicePost <- getSplittedPost(currentDockerImage)
          
          myfilepath <- createMyFilepath(currentNodeName,routingservicePre, routingservicePost%+% "_" %+% splittedTopicPost)
 
          
          print(myfilepath)
          
          createConfigMap(currentDockerImage %+%"-"%+% splittedTopicPost,filepath = myfilepath)
          
          mystring <- "  TOPIC_OUTPUT: " %+% splittedTopicPost
          write(mystring,file=myfilepath,append=TRUE)
          mystring <- "  TOPIC_INPUT: "  %+% splittedTopicPost %+% "_raw"
          write(mystring,file=myfilepath,append=TRUE)
      
      ## TODO deploymentet indítani futásidőben!
          
          rspodpath <- createMyFilepath(currentNodeName,routingservicePre, routingservicePost%+% "_" %+% splittedTopicPost,folder = "pods")
          print(rspodpath)
          
          rsConfmap <- str_replace_all(routingservicePre, "_","-") %+%"."%+%routingservicePost %+% "-" %+% splittedTopicPost
          createRSPod(currentDockerImage,rsConfmap , rspodpath)
        
      }
    }
  }
}


#    ____                                       ____
#   / __/________ _            ____  ________  / __/
#  / /_/ ___/ __ `/  ______   / __ \/ ___/ _ \/ /_
# / __/ /__/ /_/ /  /_____/  / /_/ / /  /  __/ __/
#/_/  \___/\__,_/           / .___/_/   \___/_/
#                          /_/

## ha van egy vagy több node amire mehet ÉS van reconf lehetőség, akkor arra kell tenni a prefet ami reconf nélküli
## de ha már akkor labelezünk amikor csináljuk az fca_schedulable labelt, akkor itt nem kell.



##multi nodes with reconf... todo


