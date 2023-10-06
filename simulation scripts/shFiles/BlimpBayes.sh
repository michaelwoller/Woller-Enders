echo "
DATA: ${1}/data.dat;
VARIABLES: y x1:x${3};
MODEL:
y ~ x1:x${3};
TEST:
y ~ 1;
SEED: ${2};
BURN: 10000;
ITERATIONS: 10000;
SAVE:
psr = psr.dat;
waldtest = Blimpwald.dat;
estimates = BlimpBayesestimates.dat;
"