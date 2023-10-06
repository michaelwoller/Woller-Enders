#!/bin/sh
#$ -cwd
#$ -o  /u/project/cenders/mwoller/sim251/joboutputs/251_$JOB_ID.txt
#$ -j y
#  Resources requested
#$ -l h_data=4000m,h_rt=2:00:00
#$ -t 1-2000:2

# 1-MAX REP:BY REP per CLUSTER, h_rt:REQUEST TIME
#  change above by what is needed

# sim variables
RUNONCLUSTER=1
MULTIPLE=2
DIRNAME=sim251
NUMREPS=2000

LAMBDA=(.15 .25)
N=(50 100 150 250 500 1000)
RSQ=(0 0.02 0.07 0.13 0.26) 
NUMX=(1 2 5 10)

ALPHA=(0.1 0.05 0.01)

# file paths
if [ ${RUNONCLUSTER} = 0 ]
then

	# PATHS
	WRKDIR=/users/michael/desktop/${DIRNAME}
	TMPDIR=/users/michael/desktop/${DIRNAME}/temp
	MPATH=/Applications/mplus/mplus
	RPATH=R
	SGE_TASK_ID=1

else	

	# PATHS
	WRKDIR=/u/project/cenders/mwoller/${DIRNAME}
	MPATH=mplus
	RPATH=R
	BLIMPPATH=blimp

	# LOAD MODULES
	. /u/local/Modules/default/init/modules.sh
	module use /u/project/cenders/apps/modulefiles
	module load mplus
	module load blimp/3.1.24b 
	module load R/4.1.0

fi

# remove files (comment out if you do not wish to remove files before the simulation)
rm ${WRKDIR}/finalized/CoeffNonNormal/*.*
rm ${WRKDIR}/finalized/WaldNonNormal/*.*

rm ${WRKDIR}/outputs/MLNonNormal/*.*
rm ${WRKDIR}/outputs/MLRNonNormal/*.*
rm ${WRKDIR}/outputs/BayesNonNormal/*.*
rm ${WRKDIR}/outputs/BayesYJNonNormal/*.*

rm ${WRKDIR}/results/MLNonNormal/*.*
rm ${WRKDIR}/results/MLRNonNormal/*.*
rm ${WRKDIR}/results/BayesNonNormal/*.*
rm ${WRKDIR}/results/BayesYJNonNormal/*.*
rm ${WRKDIR}/results/psrNonNormal/*.*
rm ${WRKDIR}/results/psrYJNonNormal/*.*


echo "start time: " ` date `

# REP RANGE
REPFIRST=${SGE_TASK_ID}
REPLAST=$((${REPFIRST} + ${MULTIPLE}))

# loop for each N in array
for (( NSIZE = 0; NSIZE < ${#N[@]}; NSIZE++ )); do 

	# loop for each NUMX in array
	for (( NX = 0; NX < ${#NUMX[@]}; NX++ )); do

		# loop for each Rsq in array
		for (( NRSQ = 0; NRSQ < ${#RSQ[@]}; NRSQ++ )); do

			#loop for each lambda in array
			for (( NL = 0; NL < ${#LAMBDA[@]}; NL++ )); do

				# loop from 1 to specified repetitions
				for (( REPNUM = ${REPFIRST}; REPNUM < ${REPLAST}; REPNUM++ )); do

					echo "loop is N=${N[NSIZE]} NUMX=${NUMX[NX]} RSQ=${RSQ[NRSQ]} LAMB=${LAMBDA[NL]}"

					SEEDLINE1=$((${NSIZE} * ${#NUMX[@]} * ${#RSQ[@]} * ${NUMREPS}))
					SEEDLINE2=$((${NX} * ${#RSQ[@]} * ${NUMREPS}))
					SEEDLINE3=$((${NRSQ[@]} * ${NUMREPS} + ${REPNUM}))
					SEEDLINENUM=$((${SEEDLINE1} + ${SEEDLINE2} + ${SEEDLINE3}))

					echo "get seed value from file"
					SEED=$(sed -n "${SEEDLINENUM}p" "${WRKDIR}/misc/seedlist.txt") 

					echo "Repetition ${REPNUM} has seed value ${SEED}"

					echo "data generation" 
					${RPATH} --no-save --slave --args ${TMPDIR} ${N[NSIZE]} ${REPNUM} ${SEED} ${RSQ[NRSQ]} ${NUMX[NX]} ${LAMBDA[NL]} ${RUNONCLUSTER} ${WRKDIR} < ${WRKDIR}/programs/nonnormaldatagen.R

					echo "MLR estimation with mplus" 
					sh ${WRKDIR}/shFiles/MplusMLR.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/MLRestimate.inp
					${MPATH} ${TMPDIR}/MLRestimate.inp ${TMPDIR}/mlrresults.out  > /dev/null

					echo "ML estimation with mplus" 
					sh ${WRKDIR}/shFiles/MplusML.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/MLestimate.inp
					${MPATH} ${TMPDIR}/MLestimate.inp ${TMPDIR}/mlresults.out  > /dev/null

					echo "Bayes estimation with Blimp"
					sh ${WRKDIR}/shFiles/BlimpBayes.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/BlimpBayesestimate.imp 
					${BLIMPPATH} ${TMPDIR}/BlimpBayesestimate.imp --output ${TMPDIR}/bayesresults.blimp-out > /dev/null

					echo "Yeo-Johnson Bayes estimation with Blimp"
					sh ${WRKDIR}/shFiles/BlimpBayesYeoJohnson.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/BlimpBayesYJestimate.imp 
					${BLIMPPATH} ${TMPDIR}/BlimpBayesYJestimate.imp --output ${TMPDIR}/bayesYJresults.blimp-out > /dev/null

					echo "get results"
					${RPATH} --no-save --slave --args  ${WRKDIR} ${TMPDIR} ${N[NSIZE]} ${REPNUM} ${NUMX[NX]} ${RSQ[NRSQ]} ${LAMBDA[NL]} ${ALPHA[*]} ${RUNONCLUSTER} < ${WRKDIR}/programs/getresultsnonnormal.R

					# Moving the MLR outputs
					mv ${TMPDIR}/mlrresults.out ${WRKDIR}/outputs/MLRNonNormal/N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.out
					mv ${TMPDIR}/MLRestimates.dat ${WRKDIR}/results/MLRNonNormal/MLR.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat

					# Moving the ML outputs
					mv ${TMPDIR}/mlresults.out ${WRKDIR}/outputs/MLNonNormal/N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.out
					mv ${TMPDIR}/MLestimates.dat ${WRKDIR}/results/MLNonNormal/ML.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat

					# Moving the Yeo-Johnson Bayes outputs
					mv ${TMPDIR}/bayesYJresults.blimp-out ${WRKDIR}/outputs/BayesYJNonNormal/BlimpYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.out
					mv ${TMPDIR}/BlimpBayesYJestimates.dat ${WRKDIR}/results/BayesYJNonNormal/BlimpBayesYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat
					mv ${TMPDIR}/BlimpYJwald.dat ${WRKDIR}/results/BlimpwaldYJNonNormal/BlimpwaldYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat
					mv ${TMPDIR}/psrYJNonNormal.dat ${WRKDIR}/results/psrYJNonNormal/psrYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat

					# Moving the Bayes outputs
					mv ${TMPDIR}/bayesresults.blimp-out ${WRKDIR}/outputs/BayesNonNormal/Blimp.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.out
					mv ${TMPDIR}/BlimpBayesestimates.dat ${WRKDIR}/results/BayesNonNormal/BlimpBayes.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat
					mv ${TMPDIR}/Blimpwald.dat ${WRKDIR}/results/BlimpwaldNonNormal/Blimpwald.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat
					mv ${TMPDIR}/psrNonNormal.dat ${WRKDIR}/results/psrNonNormal/psr.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.LAMB${LAMBDA[NL]}.REP${REPNUM}.dat

					rm ${TMPDIR}/*
				done
			done
		done
	done
done


echo "end time: " ` date `

