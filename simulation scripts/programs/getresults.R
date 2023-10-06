# is program being executed from a shell script?
runfromshell <- T

# inherit arguments from shell script or specify manually for testing
if(runfromshell){
  RUNVARS <- commandArgs(T)
  WRKDIR <- RUNVARS[1]
  TMPDIR <- RUNVARS[2]
  N <- as.numeric(RUNVARS[3])
  REP <- as.numeric(RUNVARS[4])
  numX <- as.numeric(RUNVARS[5])
  RSQ <- as.numeric(RUNVARS[6])
  alpha <- as.numeric(RUNVARS[7:9])
  RUNONCLUSTER <- as.numeric(RUNVARS[10])
} else {
  WRKDIR <- "~/desktop/sim251"
  TMPDIR <- "~/desktop/sim251/temp"
  N <- 50
  REP <- 1
  numX <- 2
  RSQ <- 0.15
  alpha <- c(0.1, 0.05, 0.01)
  RUNONCLUSTER <- 0
}


# set paths
setwd(WRKDIR)
if(RUNONCLUSTER == 1){TMPDIR <- c(paste0(Sys.getenv("TMPDIR"), "/"))} else if(RUNONCLUSTER == 0){TMPDIR <- c(paste0(getwd(), "/temp/"))}


setwd(TMPDIR)

####################################
# MLR
####################################

## MLR coefficients and Wald test

Fresults <- scan("MLRestimates.dat") 

# This extracts relevant output from the Mplus scripts
FmeanL <- numX+1
FcoeffL <- numX
FvarL <- (1 + numX + choose(numX,2))
FmeanSEL <- numX + 1
FcoeffSEL <- numX
FcoeffSEstart <- (FmeanL + FcoeffL + FvarL + FmeanSEL)

Fcoeff <- Fresults[(FmeanL+1):(FmeanL + FcoeffL)]
FcoeffSE <- Fresults[(FcoeffSEstart + 1):(FcoeffSEstart + FcoeffSEL)]


FCresults <- cbind(Fcoeff,FcoeffSE)

FWald <- Fresults[length(Fresults)-3]
FWdf <- Fresults[length(Fresults)-2]
FWp <- Fresults[length(Fresults)-1]

sig.at.10 <- 0
sig.at.05 <- 0
sig.at.01 <- 0
if(FWp <= alpha[1]){sig.at.10 <- 1}
if(FWp <= alpha[2]){sig.at.05 <- 1}
if(FWp <= alpha[3]){sig.at.01 <- 1}

FWresults <- cbind(FWald, FWdf, FWp, sig.at.10, sig.at.05, sig.at.01)

####################################
# ML
####################################

## ML coefficients and Wald test

setwd(TMPDIR)
FNRresults <- scan("MLestimates.dat") 

# This extracts relevant output from the Mplus scripts
FNRmeanL <- numX+1
FNRcoeffL <- numX
FNRvarL <- (1 + numX + choose(numX,2)) 
FNRmeanSEL <- numX + 1
FNRcoeffSEL <- numX
FNRcoeffSEstart <- (FNRmeanL + FNRcoeffL + FNRvarL + FNRmeanSEL)

FNRcoeff <- FNRresults[(FNRmeanL+1):(FNRmeanL + FNRcoeffL)]
FNRcoeffSE <- FNRresults[(FNRcoeffSEstart + 1):(FNRcoeffSEstart + FNRcoeffSEL)]

FNRCresults <- cbind(FNRcoeff,FNRcoeffSE)

FNRWald <- FNRresults[length(FNRresults)-3]
FNRWdf <- FNRresults[length(FNRresults)-2]
FNRWp <- FNRresults[length(FNRresults)-1]

sig.at.10 <- 0
sig.at.05 <- 0
sig.at.01 <- 0
if(FNRWp <= alpha[1]){sig.at.10 <- 1}
if(FNRWp <= alpha[2]){sig.at.05 <- 1}
if(FNRWp <= alpha[3]){sig.at.01 <- 1}

FNRWresults <- cbind(FNRWald, FNRWdf, FNRWp, sig.at.10, sig.at.05, sig.at.01)

####################################
# Bayes
####################################

# Bayes coefficients

Bresults <- scan("BlimpBayesestimates.dat") 

# This extracts relevant output from the Blimp output
BCSE <- 2
BlineL <- 6
min<- (BlineL*2)+ 1 

BNlines <- 1:numX

Bintercept <- Bresults[(BlineL+1):(BlineL + BCSE)]
BcoeffSE <- Bresults[(min):(min+BCSE)]
BcoeffL <- Bresults[]

first <- (min + BlineL)

# Matrix of relevent lines
max <- BlineL*numX - 1
all <- Bresults[min:(min + max)]
all <- matrix(all, nrow = numX, ncol = 6, byrow = TRUE)

# Getting the first two elements off of each line
var_names <- paste("V", 1:numX, sep = "")

for (i in 1:numX) {
  assign(var_names[i],all[i,1:2])
}

p_all <- mget(var_names, envir = globalenv())
d <- lapply(p_all, rbind)
BCresults <- do.call(rbind, d)  

#####

## Bayes Wald tests

Bwald.big <- read.table("Blimpwald.dat") 
Bwald.line <- Bwald.big[2,]
Bwald.line <- as.numeric(as.vector(Bwald.line[1,]))
BWald <- Bwald.line[3]
BWdf <- Bwald.line[2]
BWp <- Bwald.line[4]

sig.at.10 <- 0
sig.at.05 <- 0
sig.at.01 <- 0
if(BWp <= alpha[1]){sig.at.10 <- 1}
if(BWp <= alpha[2]){sig.at.05 <- 1}
if(BWp <= alpha[3]){sig.at.01 <- 1}

BWresults <- cbind(BWald, BWdf, BWp, sig.at.10, sig.at.05, sig.at.01)

#####

## Psr output

psr <- read.table("psr.dat") # PSR DATA

converge <- 0 # 0 = no file, 1 = file exists but max psr > 1.05, 2 = converged w max psr < 1.05
if(max(psr[20,], na.rm = T) > 1.05 & max(psr[20,], na.rm = T) != 999){converge <- 1} # 1 = file exists but max psr > 1.05
if(max(psr[20,], na.rm = T) < 1.05){converge <- 2} # 2 = converged w max psr < 1.05

PSRresults <- cbind(REP, N, RSQ, numX, psr[20,])

####################################
# Yeo-Johnson Bayes
####################################

# Yeo-Johnson Bayes coefficients

Bresults <- scan("BlimpBayesYJestimates.dat") #BayesT estiamtes

BCSE <- 2
BlineL <- 6
min<- (BlineL*2)+ 1 

BNlines <- 1:numX

Bintercept <- Bresults[(BlineL+1):(BlineL + BCSE)]
BcoeffSE <- Bresults[(min):(min+BCSE)]
BcoeffL <- Bresults[]


first <- (min + BlineL)

# Matrix of relevent lines
max <- BlineL*numX - 1
all <- Bresults[min:(min + max)]
all <- matrix(all, nrow = numX, ncol = 6, byrow = TRUE)

# Getting the first two elements off of each line
var_names <- paste("V", 1:numX, sep = "")

for (i in 1:numX) {
  assign(var_names[i],all[i,1:2])
}

p_all <- mget(var_names, envir = globalenv())
d <- lapply(p_all, rbind)
BTCresults <- do.call(rbind, d)  

## Yeo-Johnson Bayes Wald tests

Bwald.big <- read.table("BlimpYJwald.dat") 
Bwald.line <- Bwald.big[2,]
Bwald.line <- as.numeric(as.vector(Bwald.line[1,]))
BTWald <- Bwald.line[3]
BTWdf <- Bwald.line[2]
BTWp <- Bwald.line[4]

sig.at.10 <- 0
sig.at.05 <- 0
sig.at.01 <- 0
if(BTWp <= alpha[1]){sig.at.10 <- 1}
if(BTWp <= alpha[2]){sig.at.05 <- 1}
if(BTWp <= alpha[3]){sig.at.01 <- 1}

BTWresults <- cbind(BTWald, BTWdf, BTWp, sig.at.10, sig.at.05, sig.at.01)

#####

## psr results

psr <- read.table("psrYJ.dat") 

convergeT <- 0 # 0 = no file, 1 = file exists but max psr > 1.05, 2 = converged w max psr < 1.05
if(max(psr, na.rm = T) > 1.05 & max(psr, na.rm = T) != 999){converge <- 1} # 1 = file exists but max psr > 1.05
if(max(psr, na.rm = T) < 1.05){converge <- 2} # 2 = converged w max psr < 1.05

PSRTresults <- cbind(REP, N, RSQ, numX, psr)


########################################## 
# save data
##########################################

coeffIndex <- 1:numX

waldresults.out <- cbind(REP, N, RSQ, numX, FWresults, FNRWresults, BWresults, converge, BTWresults, convergeT)
print(waldresults.out)
coeffresults.out <- cbind(REP, N, RSQ, numX, FCresults, FNRCresults, BCresults, BTCresults, coeffIndex)


Coeff.path <- paste0(WRKDIR, "/finalized/Coeff")
Wald.path <- paste0(WRKDIR, "/finalized/WaldLast")
psr.path <- paste0(WRKDIR, "/finalized/psr")
psrt.path <- paste0(WRKDIR, "/finalized/psrYJ")

# Saving Coefficient output
setwd(Coeff.path)
Coeff.filename <- paste0("Coeffsimresults", ".N", N, ".NUMX", numX, ".RSQ", RSQ, ".REP", REP, ".dat")
gdata::write.fwf(coeffresults.out, Coeff.filename, rownames = F, colnames = F, width = rep(15, ncol(coeffresults.out)))

# Saving Wald output
setwd(Wald.path)
Wald.filename <- paste0("Waldsimresults", ".N", N, ".NUMX", numX, ".RSQ", RSQ, ".REP", REP, ".dat")
gdata::write.fwf(waldresults.out, Wald.filename, rownames = F, colnames = F, width = rep(15, ncol(waldresults.out)))


# Saving PSR output
setwd(psr.path)
psr.filename <- paste0("PSR", ".N", N, ".NUMX", numX, ".RSQ", RSQ, ".REP", REP, ".dat")
gdata::write.fwf(PSRresults, psr.filename, rownames = F, colnames = F, width = rep(15, ncol(PSRresults)))


# Saving Yeo-Johnson PSR output
setwd(psrt.path)
psr.filename <- paste0("PSRT", ".N", N, ".NUMX", numX, ".RSQ", RSQ, ".REP", REP, ".dat")
gdata::write.fwf(PSRTresults, psrt.filename, rownames = F, colnames = F, width = rep(15, ncol(PSRTresults)))
