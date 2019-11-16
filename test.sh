make clean
make
rm ./my.stdout
touch ./my.stdout
./tesla-attack >| ./my.stdout
