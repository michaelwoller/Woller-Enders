echo "
DATA: ${1}/data.dat;
VARIABLES: y x1:x${3};
TRANSFORM:
Ycent = y – 50;
MODEL:
yjt(Ycent) ~ x1:x${3};
TEST:
yjt(Ycent) ~ 1;
SEED: ${2};
BURN: 10000;
ITERATIONS: 10000;
SAVE:
psr = psrYJ.dat;
waldtest = BlimpYJwald.dat;
estimates = BlimpBayesYJestimates.dat;
"