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


#Order of (FIML) output
# mean estimates (Y is intercept?) (length = NUMX + 1)
#   Coefficients of predictors (length = NUMX)
#     Residual Variance (Y variance)
#       Var-Covar matrix in top left to the right order (in 2x2, Var(x1) covar(x1,x2), Var(x2)) (length = NUMX + (NUMX choose 2))
#         Mean SEs (length = NUMX + 1)
#           Intercept SE (length = NUMX)

########################

setwd(TMPDIR)

# Bayes

Bresults <- scan("BlimpBayesestimates.dat") #Bayes estiamtes

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

## Bayes Wald

Bwald.big <- read.table("Blimpwald.dat") # Bayes Wald
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

########################################## ########################################## ########################################## ########################################## ########################################## ########################################## ########################################## ########################################## ########################################## ########################################## ########################################## 
psr <- read.table("psr.dat") # PSR DATA

converge <- 0 # 0 = no file, 1 = file exists but max psr > 1.05, 2 = converged w max psr < 1.05
if(max(psr[20,], na.rm = T) > 1.05 & max(psr[20,], na.rm = T) != 999){converge <- 1} # 1 = file exists but max psr > 1.05
if(max(psr[20,], na.rm = T) < 1.05){converge <- 2} # 2 = converged w max psr < 1.05

PSRresults <- cbind(REP, N, RSQ, numX, psr[20,])

########################################## 
# save data
##########################################

coeffIndex <- 1:numX

waldresults.out <- cbind(REP, N, RSQ, numX, BWresults, converge)


Wald.path <- paste0(WRKDIR, "/finalized/WaldSecond")
psr.path <- paste0(WRKDIR, "/finalized/psrSecond")

# Saving Wald output
setwd(Wald.path)
Wald.filename <- paste0("Waldsimresults", ".N", N, ".NUMX", numX, ".RSQ", RSQ, ".REP", REP, ".dat")
gdata::write.fwf(waldresults.out, Wald.filename, rownames = F, colnames = F, width = rep(15, ncol(waldresults.out)))



# Saving PSR output
setwd(psr.path)
psr.filename <- paste0("PSR", ".N", N, ".NUMX", numX, ".RSQ", RSQ, ".REP", REP, ".dat")
gdata::write.fwf(PSRresults, psr.filename, rownames = F, colnames = F, width = rep(15, ncol(PSRresults)))
