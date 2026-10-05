#Start
LDA I $00;
LDB I $00;
STA X $3000;
LDA I $01;
LDB I $01;
STA X $3000;

LDA B;
ADD I $01;
TSU B;

#Build
LDA B;
CEQ I $0E;
JSZ #ReadBack;

LDA X $2FFF;
ADD X $2FFE;
TSU A;
STA X $3000;

LDA B;
ADD I $01;
TSU B;
JMP #Build;

#ReadBack
LDB I $00;

#ReadLoop
LDA B;
CEQ I $0E;
JSZ #Done;

LDA X $3000;
PSH A;

LDA B;
ADD I $01;
TSU B;
JMP #ReadLoop;

#Done
HLT;