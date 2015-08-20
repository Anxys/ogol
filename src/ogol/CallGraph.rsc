module ogol::CallGraph
import ListRelation;
import ogol::Syntax;
import IO;
import ParseTree;
import analysis::graphs::Graph;

alias FunctionCalls = Graph[str];
alias FunctionsDef = List[str];

//Get All Function Call locations
map[str, tuple[str,str]] getFuncCallLocs(){
        Program p = parse(#start[Program], |project://Ogol/input/dashed_nested.ogol|).top;
		map[str, tuple[str,str]] calls = (); 

        for (/FunDef def <- p.commands){
                for(/FunCall call := def.commands){
                  calls["<call@\loc>"] = <"<def.id>", "<call.id>">;	
                }	
        }
        return calls;
}
//Provide a function name to see from which functions it reachable
list[str] getReachableFunctions(str funcName){
        Program p = parse(#start[Program], |project://Ogol/input/dashed_nested.ogol|).top;
        lrel[str, str] calls = [];
        for (/FunDef def <- p.commands){
                for(/FunCall call := def.commands){
                  calls += <"<def.id>", "<call.id>">;	
                }	
        }
        //funcName + graph+ ...?
        calls = invert(calls+); //Todo just switch the tuple in the enumerator...
	
        return calls["<funcName>"];
}



lrel[str,str,str] main(list[value] args){
        Program p = parse(#start[Program], |project://Ogol/input/dashed_nested.ogol|).top;
        list[str] funDefs = [];;
        FunctionCalls graph = {};
        lrel[str,str, str] calls = [];

        for (/FunDef def <- p.commands){
        		funDefs += "<def.id>";	
                for(/FunCall call := def.commands){
                  graph += <"<def.id>", "<call.id>">;	
                  calls += <"<call@\loc>","<def.id>", "<call.id>" >;	
                }	
        }

		//Number of Calls graph 
		println("Size:");
		println(size(calls));
		//number of procs 
		println("Number of Procs:");
		println(size(funDefs));
		//Entry point
		println("Entry Point:");
		println(top(graph));
		//Leaves
		println("Leaves:");
		println(bottom(graph));
		//Closures
		println("Closures:");
		println(graph+);

        return calls;
}
















FunctionCalls functionDefsUsedInCommands(Command* c){
        graph = {};
        for(/FunDef def  := c){ 
                for(/FunCall call := def.commands){
                  graph += <"<def.id>", "<call>">;	
                }	
        };

        return graph;
}


test void tesxt(){ Program p = parse(#start[Program], |project://Ogol/input/dashed.ogol|).top; 
}
test bool findFuns() = (Program)`forward 10;` := desugar((Program)`fd 10;`);