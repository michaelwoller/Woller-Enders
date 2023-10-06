#!/bin/sh
#$ -cwd
#$ -o  /u/project/cenders/mwoller/sim251/joboutputs/251_$JOB_ID.txt
#$ -j y
#  Resources requested
#$ -l h_data=2000m,h_rt=0:45:00
#$ -t 1-1:1

# sim variables
RUNONCLUSTER=1
MULTIPLE=1
DIRNAME=sim251
NUMREPS=1

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
rm ${WRKDIR}/finalized/Coeff/*.*
rm ${WRKDIR}/finalized/Wald/*.*

rm ${WRKDIR}/outputs/ML/*.*
rm ${WRKDIR}/outputs/MLR/*.*
rm ${WRKDIR}/outputs/Bayes/*.*
rm ${WRKDIR}/outputs/BayesYJ/*.*

rm ${WRKDIR}/results/ML/*.*
rm ${WRKDIR}/results/MLR/*.*
rm ${WRKDIR}/results/Bayes/*.*
rm ${WRKDIR}/results/BayesYJ/*.*
rm ${WRKDIR}/results/psr/*.*
rm ${WRKDIR}/results/psrYJ/*.*

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

			# loop from 1 to specified repetitions
			for (( REPNUM = ${REPFIRST}; REPNUM < ${REPLAST}; REPNUM++ )); do

				echo "loop is N=${N[NSIZE]} NUMX=${NUMX[NX]} RSQ=${RSQ[NRSQ]}"

				SEEDLINE1=$((${NSIZE} * ${#NUMX[@]} * ${#RSQ[@]} * ${NUMREPS}))
				SEEDLINE2=$((${NX} * ${#RSQ[@]} * ${NUMREPS}))
				SEEDLINE3=$((${NRSQ[@]} * ${NUMREPS} + ${REPNUM}))
				SEEDLINENUM=$((${SEEDLINE1} + ${SEEDLINE2} + ${SEEDLINE3}))

				echo "get seed value from file"
				SEED=$(sed -n "${SEEDLINENUM}p" "${WRKDIR}/misc/seedlist.txt") 

				echo "Repetition ${REPNUM} has seed value ${SEED}"

				echo "data generation" 
				${RPATH} --no-save --slave --args ${TMPDIR} ${N[NSIZE]} ${REPNUM} ${SEED} ${RSQ[NRSQ]} ${NUMX[NX]} ${RUNONCLUSTER} ${WRKDIR} < ${WRKDIR}/programs/datagen.R

				echo "MLR estimation with mplus" 
				sh ${WRKDIR}/shFiles/MplusMLR.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/MLRestimate.inp
				${MPATH} ${TMPDIR}/MLRestimate.inp ${TMPDIR}/MLRresults.out  > /dev/null

				echo "ML estimation with mplus" 
				sh ${WRKDIR}/shFiles/MplusML.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/MLestimate.inp
				${MPATH} ${TMPDIR}/FMLestimate.inp ${TMPDIR}/MLresults.out  > /dev/null

				echo "Bayes estimation with Blimp"
				sh ${WRKDIR}/shFiles/BlimpBayes.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/BlimpBayesestimate.imp 
				${BLIMPPATH} ${TMPDIR}/BlimpBayesestimate.imp --output ${TMPDIR}/bayesresults.blimp-out > /dev/null

				echo "Bayes Transformed estimation with Blimp"
				sh ${WRKDIR}/shFiles/BlimpTransform.sh ${TMPDIR} ${SEED} ${NUMX[NX]} > ${TMPDIR}/BlimpBayesTestimate.imp 
				${BLIMPPATH} ${TMPDIR}/BlimpBayesTestimate.imp --output ${TMPDIR}/bayesTresults.blimp-out > /dev/null

				echo "get results"
				${RPATH} --no-save --slave --args  ${WRKDIR} ${TMPDIR} ${N[NSIZE]} ${REPNUM} ${NUMX[NX]} ${RSQ[NRSQ]} ${ALPHA[*]} ${RUNONCLUSTER} < ${WRKDIR}/programs/results.R

				# Moving ML results
				mv ${TMPDIR}/MLresults.out ${WRKDIR}/outputs/ML/N${N[NSIZE]}NUMX${NUMX[NX]}RSQ${RSQ[NRSQ]}REP${REPNUM}.out
				mv ${TMPDIR}/MLestimates.dat ${WRKDIR}/results/ML/ML.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat

				# Moving MLR results
				mv ${TMPDIR}/MLRresults.out ${WRKDIR}/outputs/MLR/N${N[NSIZE]}NUMX${NUMX[NX]}RSQ${RSQ[NRSQ]}REP${REPNUM}.out
				mv ${TMPDIR}/MLRestimates.dat ${WRKDIR}/results/MLR/MLR.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat

				# Moving Blimp results
				mv ${TMPDIR}/bayesresults.blimp-out ${WRKDIR}/outputs/Bayes/BlimpN${N[NSIZE]}NUMX${NUMX[NX]}RSQ${RSQ[NRSQ]}REP${REPNUM}.out
				mv ${TMPDIR}/BlimpBayesestimates.dat ${WRKDIR}/results/Bayes/BlimpBayes.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat
				mv ${TMPDIR}/Blimpwald.dat ${WRKDIR}/results/Blimpwald/Blimpwald.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat
				mv ${TMPDIR}/psr.dat ${WRKDIR}/results/psr/psr.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat
				
				# Moving the Yeo-Johnson Bayes outputs
				mv ${TMPDIR}/bayesYJresults.blimp-out ${WRKDIR}/outputs/BayesYJ/BlimpYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.out
				mv ${TMPDIR}/BlimpBayesYJestimates.dat ${WRKDIR}/results/BayesYJ/BlimpBayesYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat
				mv ${TMPDIR}/BlimpYJwald.dat ${WRKDIR}/results/BlimpwaldYJ/BlimpwaldYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat
				mv ${TMPDIR}/psrYJ.dat ${WRKDIR}/results/psrYJ/psrYJ.N${N[NSIZE]}.NUMX${NUMX[NX]}.RSQ${RSQ[NRSQ]}.REP${REPNUM}.dat

				rm ${TMPDIR}/*
			done

		done
	done
done

echo "end time: " ` date `

