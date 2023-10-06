
runfromshell <- T # set to F if running locally
#shell script function for simulation features
if(runfromshell){
  RUNVARS <- commandArgs(T) 
  TMPDIR <-  RUNVARS[1] 
  N <- as.numeric(RUNVARS[2]) 
  repnum <- as.numeric(RUNVARS[3])
  seed <- as.numeric(RUNVARS[4]) 
  Rsq <- as.numeric(RUNVARS[5]) 
  numX <- as.numeric(RUNVARS[6]) 
  RUNONCLUSTER <- as.numeric(RUNVARS[7])
  WRKDIR <- RUNVARS[8]
} else {
  WRKDIR <- "~/desktop/sim251"
  TMPDIR <- "~/desktop/sim251/temp" #change this to whatever you have your folders named
  N <- 50
  repnum <- 2000
  seed <- 80421256
  Rsq <- c(0,.02,.07,.13,.26)
  numX <- 10
  RUNONCLUSTER <- 0
}

# set paths
setwd(WRKDIR)
if(RUNONCLUSTER == 1){TMPDIR <- c(paste0(Sys.getenv("TMPDIR"), "/"))} else if(RUNONCLUSTER == 0){TMPDIR <- c(paste0(getwd(), "/temp/"))}


###########################
# Function to solve for regression slopes
###########################

coeff.function <- function(Rsq, var.Y, importance.weights, mu, sigma){ 
  
  scaling.ratios <- (1 / sqrt(sigma[nrow(sigma),ncol(sigma)])) * sqrt(diag(sigma)) 

  beta.Z <- rep(1,length(scaling.ratios)) * scaling.ratios * importance.weights
  var.Z <- t(beta.Z) %*% sigma %*% beta.Z
  mu.Z <- mu %*% beta.Z
  
  G1.Z <- sqrt((Rsq * var.Y) / var.Z)
  var.E <- varY - G1.Z^2 * var.Z

  G1 <- beta.Z * c(G1.Z) 

  return(c(G1, var.E)) 
}

################
# Defining the population model
################

####### Predictor X's

corX <- .2
muX <- rep(0, numX) 

sigmaX <- matrix(corX, nrow = numX, ncol = numX)

diag(sigmaX) <- 1 

####### Regression slopes

importance.weights <- c(rep(1,length(numX)))  

muY <- 50 
varY <- 100


coeff.output <- coeff.function(Rsq, 
                               varY, 
                               importance.weights,
                               muX,
                               sigmaX)
beta <- coeff.output[1:numX] 
beta0 <- muY - beta %*% muX 

Rsq.check <- (t(beta) %*% sigmaX %*% beta) / (t(beta) %*% sigmaX %*% beta + coeff.output[numX+1]) # analytical recreation of effect size

#######################################
# generate data set
#######################################

set.seed(seed)

Xs <- mvtnorm::rmvnorm(N, muX, sigmaX) 
    
Es <- rnorm(N, 0, sqrt(coeff.output[numX+1])) 
    
Y <- rep(beta0,N) + Xs %*% beta + Es 


#######################################
# create data and write to file
#######################################

dat <- cbind(Y,Xs)
setwd(TMPDIR)
gdata::write.fwf(dat, "data.dat", append = T, rownames = F, colnames = F, width = rep(15,ncol(dat)))
