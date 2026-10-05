Start:
LDA M $2010; //load memory value to A
ADD I $C0; //Add C0 to A
CEQ M $2120; //Compare if equal to memory value
JSZ Equal; //Jump to equal if sum is not 0 (meaning CEQ operation was true)
JMP Start; //Jump uncondiationally to start

Equal:
PSH X; //Push A to stack
end