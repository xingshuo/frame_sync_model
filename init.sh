echo -e '\033[91m--install python-pygame--\033[0m'
sudo apt-get install python-pygame
echo -e '\033[91m--git clone jemalloc to skynet/--\033[0m'
cd skynet/3rd && git clone https://github.com/jemalloc/jemalloc.git && cd ../../
echo -e '\033[91m--link server file to skynet/--\033[0m'
ln -fs $(pwd)/server $(pwd)/skynet/
echo -e '\033[91m--install pysproto--\033[0m'
make pysproto
echo -e '\033[91m--compile skynet && compile sproto--\033[0m'
make