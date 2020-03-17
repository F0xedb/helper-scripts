#!/bin/bash

# MIT License
# 
# Copyright (c) 2019 Meyers Tom
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
function help {
        subname="gpg"
        printf "${ORANGE} $name $subname ${NC}OPTIONS: info | key | export | import | upload | generate | git | help\n\n" 
        printf "${ORANGE}USAGE:${NC}\n"
        printf "$name $subname help \t\t\t\t Show this help message\n"
        printf "$name $subname info \t\t\t\t Get gpg information\n"
        printf "$name $subname key \t\t\t\t Get all key id's\n"
        printf "$name $subname export <key> \t\t\t Export your gpg key\n"
        printf "$name $subname import <file> \t\t\t Import your gpg key from a file\n"
        printf "$name $subname upload <key> <?server> \t\t Upload your key to a keyserver optionally add a server address\n"
        printf "$name $subname generate \t\t\t Generate a gpg key\n"
        printf "$name $subname git \t\t\t\t Setup your git with gpg\n"
}


case "$2" in
    "in"|"info")
            gpg --list-secret-keys --keyid-format LONG
    ;;
    "k"|"key")
            gpg --list-secret-keys --keyid-format LONG | grep -E '^sec' | awk '{print $2}' | cut -d/ -f2
    ;;
    "e"|"export")
        if [[ "$4" != "" ]]; then
                gpg --export-secret-keys "$3" > "$4"
        else
                gpg --export-secret-keys "$3"
        fi
    ;;
    "i"|"import")
        gpg import "$3"
    ;;
    "u"|"upload")
        if [[ "$4" != "" ]]; then
            gpg --keyserver "$4" --send-keys "$3"
        else
            gpg --keyserver hkp://pgp.mit.edu --send-keys "$3"
        fi
    ;;
    "ge"|"generate")
            gpg --full-generate-key
    ;;
    "gi"|"git")
            git config --global user.signingkey "$3"
            mail=$(gpg --list-secret-keys --keyid-format LONG "$3" | grep -E '^uid' | awk -F\< '{print $2}' | tr '>' ' ')
            git config --global user.email "$mail"
    ;;
    "-h"|"--help"|"help"|"h"|"")
        help
    ;;   
esac

