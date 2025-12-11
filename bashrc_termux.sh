#!/bin/bash
# Created by ZamyrDev for Termux (Android)

# Paste the following text in the $PREFIX/etc/bash.bashrc
# or type:
#    echo '[Paste text here]' >> $PATH/etc/bash.bashrc

echo -e "\n"
echo 'bash.bashrc on $PREFIX/etc/bash.bashrc'
echo -e 'call with "mybash" command \n'
alias mybash='nano $PREFIX/etc/bash.bashrc'

# extra
alias mkcd='mkdir $1 && cd $1'
