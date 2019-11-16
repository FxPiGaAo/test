make clean
make
rm -f ./my.stdout ./programout.txt
touch ./my.stdout ./programout.txt
./tesla-attack >| ./my.stdout
