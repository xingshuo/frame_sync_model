echo -e '\033[91m--install python-pygame--\033[0m'
sudo apt-get install python-pygame
echo -e '\033[91m--install autoconf--\033[0m'
sudo apt-get install autoconf
echo -e '\033[91m--install readline--\033[0m'
sudo apt-get install libreadline-dev
echo -e '\033[91m--install python-setuptools--\033[0m'
sudo apt-get install python-setuptools
echo -e '\033[91m--git clone jemalloc to skynet/--\033[0m'
cd skynet/3rd && git clone https://github.com/jemalloc/jemalloc.git
cd ../../
echo -e '\033[91m--link server file to skynet/--\033[0m'
ln -fs $(pwd)/server $(pwd)/skynet/
echo -e '\033[91m--install pysproto--\033[0m'
sudo pip install Cython
make pysproto
echo -e '\033[91m--compile skynet && compile sproto--\033[0m'
make