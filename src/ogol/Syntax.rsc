module ogol::Syntax

/*

Ogol syntax summary

Program: Command...

Command:
 * Control flow: 
  if Expr Block
  ifelse Expr Block Block
  while Expr Block
  repeat Expr Block
 * Drawing (mind the closing semicolons)
  forward Expr; fd Expr; back Expr; bk Expr; home;
  right Expr; rt Expr; left Expr; lt Expr; 
  pendown; pd; penup; pu;
 * Procedures
  definition: to Name [Var...] Command... end
  call: Name Expr... ;
 
Block: [Command...]
 
Expressions
 * Variables :x, :y, :angle, etc.
 * Number: 1, 2, -3, 0.7, -.1, etc.
 * Boolean: true, false
 * Arithmetic: +, *, /, -
 * Comparison: >, <, >=, <=, =, !=
 * Logical: &&, ||

Reserved keywords
 if, ifelse, while, repeat, forward, back, right, left, pendown, 
 penup, to, true, false, end

Bonus:
 - add literal for colors
 - support setpencolor

*/

start syntax Program = Command*; 
 
syntax FunDef = "to" FunId VarId* Command* "end";
syntax FunCall = FunId Expr* ";";

/*syntax ArithmeticExpr = (VarId | Number >> Arithmetic >> VarId | Number) |
		ArithmeticExpr >> Arithmetic >> ArithmeticExpr ; 
		
syntax BooleanExpr = (VarId | Number >> BooleanExpr >> VarId | Number) |
		BooleanExpr >> Arithmetic >> ArithmeticExpr;  */

syntax Value = VarId | Number | Boolean;
syntax Operator = Arithmetic > Comparison > Logical;
syntax Operation = Value Operator Value | Operation Operator Operation;
syntax Expr = Value | Operation;


syntax Command = ControlFlow | Drawing | FunDef | FunCall;
syntax ControlFlow = If | IfElse | While | Repeat;

syntax Directions = "forward" | "fd" | "back" | "bk" | "right" | "rt" | "left";
syntax SimpleActions = "home" | "pu"| "penup"| "pendown" | "pd";
syntax ActionExpr = Directions Expr ;
syntax Drawing = ( SimpleActions | ActionExpr )";";

syntax If = "if" Expr Block;
syntax IfElse = "ifelse"  Expr Block Block;
syntax While = "while" Expr Block;
syntax Repeat = "repeat" Expr Block; 

syntax Block = "["  Command+   "]";


keyword Reserved = "if" | "ifelse" | "while" | "repeat" | "forward" | "back" | "right"
					| "back" | "right" | "left" | "pendown" | "penup" | "to" | "true"
					| "false" | "end";

syntax Expr1 
   = Bool
   | Num
   | VarId
   > left   div: Expr "/" Expr 
   > left   mul: Expr "*" Expr
   > left ( add: Expr "+" Expr 
   		  | sub: Expr "-" Expr
   		  )
   > left ( gt:  Expr "\>"  Expr
          | st:  Expr "\<"  Expr
          | gte: Expr "\>=" Expr
          | ste: Expr "\<=" Expr
          | eq:  Expr "="  Expr
          | neq: Expr "!=" Expr
          )    
   | left ( and: Expr "&&" Expr
          | or:  Expr "||" Expr
          )
   ;

lexical Number1 = "-"?[0-9]+"."?[0-9]*;
lexical Number ="-"? ([0-9]* ".")? [0-9]+ !>> [0-9]; 
lexical Boolean = "true" | "false";
lexical Arithmetic = "/" |  "*" > "+"  |  "-";
lexical Comparison = "\>" | "\<" | "\>=" |  "\<=" |  "="  | "!=";
lexical Logical = "&&" | "||"; 

lexical VarId
  = ":" [a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9];
  
lexical FunId
  = [a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9];


layout Standard 
  = WhitespaceOrComment* !>> [\ \t\n\r] !>> "--";
  
lexical WhitespaceOrComment 
  = whitespace: Whitespace
  | comment: Comment
  ; 

lexical Whitespace
  = [\ \t\n\r]
  ;

lexical Comment
  = @category="Comment" "--" ![\n\r]* $
  ;  
  
  
  bool canParseOperation(str s){
  	return canParse(#Program, s);
  }
  
  bool canParse( str s){
   try {
   	parse(#Program, s);
   	return true;
   }catch :return false;
  }
  
   /* True */
  test bool if3() = true := canParse("if true [fd 5;]");
  test bool x3() = true := canParse("to dash :n :len repeat :n [ pd; fd :len; pu; fd :len; ] bk :len; pd;end");
  
   /* False */
  test bool n1() = false := canParse("-1-");
  test bool e2() = false := canParse("++7");
  test bool e3() = false := canParse("-+12232");
  test bool b1() = false := canParse("[]");
  

  