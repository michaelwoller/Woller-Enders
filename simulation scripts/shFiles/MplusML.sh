echo "
DATA: 
file = ${1}/data.dat;
VARIABLE: 
names = y x1-x${3};
usevariables = y x1-x${3};
MODEL: 
!x1-x${3}; !unnecessary unless we want to use this for missing data
y on x1-x${3} (b1-b${3});
MODEL TEST:
do(#,1,${3}) 0 = b#;
OUTPUT: 
tech1;
SAVE: 
results = ${1}/MLestimates.dat;
"