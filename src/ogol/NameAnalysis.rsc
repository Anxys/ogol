module ogol::NameAnalysis

import ogol::Syntax;

import ParseTree;
alias Definitions = lrel[str varName, str scopeName, int varPos];
alias Uses = rel[str varName, loc src, str scopeName, int varPos];

Uses main(list[value] args){
        Program p = parse(#start[Program], |project://Ogol/input/dashed.ogol|).top;
        return varsUsedInCommands("global", p.commands, []);
}


Uses varsUsedInCommand( str scopeName,
 (Command)`to <FunId fid> <VarId* args> <Command* commands> end`, 
Definitions defs){
        innerScope = "<scopeName>/<fid>"; int i = 0; for(arg <- args){ 
                defs = <"<arg>", innerScope, i> + defs; i += 1;
        }

        return varsUsedInCommands(innerScope, commands, defs);
}

Uses varsUsedInCommand( str scopeName, (Block) `[ <Command* commands> ]`, Definitions defs){
        varsUsedInCommands(scopeName, commands, defs);// Get vars used in commands
}
Uses varsUsedInCommands(str scopeName, Command* commands, Definitions defs)
 = { *varsUsedInCommand(scopeName, cmd, defs) | cmd <- commands };

default Uses varsUsedInCommand( str scopeName, Command command, Definitions defs) { 
        uses = {};
        for(/VarId varid := command){ 
                lrel[str scopeName, int varPos] vardefs = defs["<varid>"]; 
                if(size(vardefs) > 0){ uses += <"<varid>", varid@\loc, vardefs[0].scopeName, vardefs[0].varPos>;

                } else

                        uses += <"<varid>", varid@\loc, "***undefined***", -1>;

        };
        return uses;
}