#' @title CID_SDF
#' @param cid list of PubChem identifiers
#' @import dplyr
CID_SDF<-function(cids,query.limit=25,...){
  
  #retrieve metabolite SDF from DB
  #DB should be a list with cids as names
  #for all missing in DB, look up using PubChem PUG
  #if update then update DB with cid entries
  #return list of SDF files for each cid
  
  # make sure all are numeric
  obj<-as.numeric(as.character(unlist(cids))) %>%
    .[!duplicated(.)] %>% na.omit()

   if(length(obj) == 0)  stop("Please supply valid input as numeric PubChem CIDs")
  
  #due to url string size limit query query.limit sdf obj at a time
  blocks<-as.list(split(obj, ceiling(seq_along(1:length(obj))/query.limit)))
  SDF<-lapply(1:length(blocks),function(i){
    url<-paste0("http://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/",
                     paste(blocks[[i]] %>% unlist(),collapse=","),"/SDF")
    #format for output
    tmp<-read_sdf(url) %>% unclass(.)
    names(tmp)<-blocks[[i]]
    return(tmp)
  }) 
  
  #need to flatten list and name as cid from: http://stackoverflow.com/questions/19734412/flatten-nested-list-into-1-deep-list
  flatlist <- function(mylist){
    lapply(rapply(mylist, enquote, how="unlist"), eval)
  }
  
  #
 flatlist(SDF)
   
}  

#' @title read_sdf
read_sdf<-function (sdfstr) {
  
  #number of queries controlled in url
  if (length(sdfstr) > 1) {
    mysdf <- sdfstr
  } else {
    mysdf <- readLines(sdfstr)
  }
  
  y <- regexpr("^\\${4,4}", mysdf, perl = TRUE)
  index <- which(y != -1)
  indexDF <- data.frame(start = c(1, index[-length(index)] + 
                                    1), end = index)
  mysdf_list <- lapply(seq(along = indexDF[, 1]), function(x) mysdf[seq(indexDF[x, 
                                                                                1], indexDF[x, 2])])
  if (class(mysdf_list) != "list") {
    mysdf_list <- list(as.vector(mysdf_list))
  }
  names(mysdf_list) <- 1:length(mysdf_list)
  #mysdf_list <- new("SDFstr", a = mysdf_list)
  return(mysdf_list)
}
#' @import ChemmineR
SDF_tanimoto<-function(cmpd.DB){  
  #convert to SDFstr
  #depends on ChemmineR 
  require(ChemmineR)
  cmpd.sdf.list<-new("SDFstr", a = cmpd.DB)
  sd.list<-as(cmpd.sdf.list, "SDFset")
  cid(sd.list) <- sdfid(sd.list)
  
  # Convert base 64 encoded fingerprints to character vector, matrix or FPset object
  fpset <- fp2bit(sd.list, type=2)

  out<-sapply(rownames(fpset), function(x) ChemmineR::fpSim(x=fpset[x,], fpset,sorted=FALSE)) 
  obj<-as.matrix(out)
  
  return(obj)
}

#' @title CID_tanimoto
#' @param cid PubChem CID
#' @import ChemmineR
#' @details ... is passed to CID_SDF and SDF_tanimoto
#' @export
CID_tanimoto<-function(cids,...){
  cmpd.DB<-CID_SDF(cids,...)
  SDF_tanimoto(cmpd.DB,...)
} 