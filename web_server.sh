#!/bin/bash

perl -MIO::All -e 'io(":8704")->fork->accept->(sub { $_[0] < io(-x $1 ? "./$1 |" : $1) if /^GET \/(.*) / })'
