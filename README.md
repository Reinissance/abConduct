# abConduct
GUI for https://github.com/leesavide/abcm2ps with ability to create parts




In the header with %%score ... ... ... or %%staves... ... ... you can add for example %Partitur scale=0.7 barsperstaff=4 etc.



Example:



X:1

%%staves S A T B %Partitur scale=0.6 barsperstaff=4

%%staves S %Sopran scale=0.8 barsperstaff=8

T:XXX

C:xxx

K:C

V:S

A4|]

V:A

E4|]

V:T

B,4|]

V:B

C,4|]



Then abConduct generates seperate pdf-files which you can export at once.
