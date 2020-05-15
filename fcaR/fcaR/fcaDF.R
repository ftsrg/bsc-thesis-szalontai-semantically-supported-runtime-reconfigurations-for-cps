library(plyr)
library(fcaR)
library(stringr)
library(purrr)
library(dplyr)

## FCA magic happens here

# Merge two dataset
fca_able                  <- rbind.fill(system_capabilities, topic_requierments)
fca_able[is.na(fca_able)] <- 0
rownames(fca_able)        <- fca_able$names
fca_able                  <- subset(fca_able, select = -c(names))

fc_system <- fcaR::FormalContext$new(fca_able)

# fc_system$objects
fc_system$find_implications()

# fc_system$concepts
# fc_system$implications
# fc_system$concepts$plot()
# print(fc_system)
# fc_system$plot()


getIntents <- function(fca_system,hanyadik){
  intents <- SparseSet$new(fca_system$objects)
  intents$assign(attributes = c(fc_system$objects[hanyadik]),values = c(1))
  fc_system$intent(intents)
  fcaSetToList(fca_system$intent(intents))
}

listOfSystemIntents <- list()
for(i in 1:nrow(system_capabilities)){
  listOfSystemIntents[[length(listOfSystemIntents)+1]] <- getIntents(fc_system,i) 
}

listOfTopicIntents <- list()
for(i in 1:nrow(topic_requierments)){
  listOfTopicIntents[[length(listOfTopicIntents)+1]] <- getIntents(fc_system,nrow(system_capabilities)+i)
}


## Reduce functions: union,setdiff,intersection

###
## list of Topic Requirement Gaps, will show us, what is missing from node to fulfill topic reqs
listOfTopicReqGaps <- list()
for(k in 1:nrow(topic_requierments)){
  listOfTopicReqGapsPerTopic <- list()
  for(i in 1:nrow(system_capabilities)){
    #listOfTopicReqGaps[[length(listOfTopicReqGaps)+1]] <-  Reduce(setdiff, Topic1Intents, unlist(listOfIntents[i]))
    listOfTopicReqGapsPerTopic[[fc_system$objects[i]]] <-  Reduce(setdiff,  unlist(listOfSystemIntents[i]), unlist(listOfTopicIntents[k]))
  }
  listOfTopicReqGaps[[fc_system$objects[nrow(system_capabilities)+k]]] <-  listOfTopicReqGapsPerTopic
}

###
## Reconfing Deployments shows us, the required vsensors to fulfill topic reqs
## !!! CURRENTLY WORKS ONLY FOR ONE RECONFIG ITEM !!!!
#
ReconfigDeployments <- list()
for(k in 1:nrow(topic_requierments)){
  ReconfigDeploymentsTopic <- list()
  for(i in 1:nrow(system_capabilities)){
    perTopic <- listOfTopicReqGaps[[k]]
    perTopicName <- names(listOfTopicReqGaps)
    perSystem <- perTopic[[i]]
    if(length(perSystem) >0 ) {
     ReconfigDeploymentsTopic[[fc_system$objects[i]]] <- getSensorSubstitutabilities(unlist(listOfSystemIntents[i]),perSystem)
    }
    else{
      
     ReconfigDeploymentsTopic[[fc_system$objects[i]]] <- NA
    }
  }
  ReconfigDeployments[[fc_system$objects[nrow(system_capabilities)+k]]] <- ReconfigDeploymentsTopic
}

###
## After the reconfiguration, with added vsensor capabilites we search again for Topic needs
## if we have all needs, the [Topic]-[Node] pair is empty

for(k in 1:nrow(topic_requierments)){
  TopicReqGapsFilledTopic <- list()
  for(i in 1:nrow(system_capabilities)){
        # ha a Topic[k].BB[i] elem nem üres és van a reconfig azonos során valami, akkor azt ki kell vonni belőle
    alma <- listOfTopicReqGaps[[k]]
    alma2 <- alma[[i]]
    
    rectops <- ReconfigDeployments[[k]]
    recsystem <- rectops[[i]]
    
    if(!is.na(alma2) && !is.na(recsystem)){
    if(alma2 == recsystem$Output[1]){
      TopicReqGapsFilledTopic[[fc_system$objects[i]]] <-  Reduce(setdiff,  alma2,recsystem$Output[1])
      fcacol <- NULL
      for(fcaoszlop in 1:length(colnames(fca_able))){
       if (!is.na(match(names(fca_able2[fcaoszlop]),recsystem$Output[1])))  {
         fcacol <- fcaoszlop
       }
      }
      fca_able2[[fcacol]][[i]] <- 1
      
    }
    }
    else{
      TopicReqGapsFilledTopic[[fc_system$objects[i]]] <- alma2
    }
  }
  
  TopicReqGapsFilled[[fc_system$objects[nrow(system_capabilities)+k]]] <- TopicReqGapsFilledTopic
}





#Do not touch
set_to_string <- function(S, attributes) {
  
  idx <- which(as.numeric(S) > 0)
  
  if (length(idx) > 0) {
    A <- S[idx]
    att <- attributes[idx]
    tmp <- paste0("",
                  str_flatten(paste0(att, " [", A, "]"),
                              collapse = ","), "")
    gsub(pattern = "( \\[1\\])",
         replacement = "",
         x = tmp)
  } else {
    ""
  }
}
## input an fcaR object or attributset, output List
fcaSetToList <- function(FCASET) {
  if (sum(FCASET$.__enclos_env__$private$v) > 0) {
    myvar <-
      (stringr::str_wrap(
        set_to_string(
          S = FCASET$.__enclos_env__$private$v,
          attributes = FCASET$.__enclos_env__$private$attributes
        ),
        width = 75,
        exdent = 2
      ))
  } else {
    myvar <- ("")
  }
  
  myvar <- str_replace_all(myvar, "\n ", "")
  mylist <- as.list(strsplit(myvar, ',')[[1]])
}
