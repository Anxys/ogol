module ogol::Eval

import ogol::Syntax;
import ogol::Canvas;
import ParseTree;
import String;
import util::Math;
import IO;
alias FunEnv = map[FunId id, FunDef def];

alias VarEnv = map[VarId id, Value val];

data Value
  = boolean(bool b)
  | number(real r)
  ;

/*
         +y
         |
         |
         |
-x ------+------- +x
         |
         |
         |
        -y

NB: home = (0, 0)
*/


alias Turtle = tuple[int dir, bool pendown, Point position];

alias State = tuple[Turtle turtle, Canvas canvas];

//Map Comprehensions are cool
FunEnv collectFunDefs(Program p) = (f.id : f| /FunDef f:= p);

// Top-level eval function
Canvas eval(p:(Program)`<Command* cmds>`){
	Program desugared = desugar(p);	
	funenv = collectFunDefs(desugared);
//	println(funenv);
	varEnv = ();
	initialState = <<0, false, <0,0>>,[]>;
	state = initialState;

	for (c <- desugared.commands){
	    println(unparse(c));
		state = eval(c, funenv, varEnv, state);
	}
	return state.canvas;
}



Program desugar(p:(Program)`<Command* cmds>`){
  return visit (p) {
  	case (ControlFlow)`if <Expr e> <Block b>` => (ControlFlow)`ifelse <Expr e> <Block b> []`
    case (Expr)`<Expr l>  \<= <Expr r>`=> (Expr)`<Expr r> \>= <Expr l>`   
    case (Expr)`<Expr l>  \< <Expr r>`=> (Expr)`<Expr r> \> <Expr l>`   
    case (Directions)`fd`=> (Directions)`forward`   
    case (Directions)`bk`=> (Directions)`back`   
    case (Directions)`rt`=> (Directions)`right`   
    case (Directions)`lt`=> (Directions)`left` 
    case (PenActions)`pu`=> (PenActions)`penup`   
    case (PenActions)`pd`=> (PenActions)`pendown`   
  };
}


//sin(??)*fd = y  cos(??)* fd = x
//Radial = 180 degrees / pie..yum
State eval((Command)`forward <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){
		curLoc = <state.turtle.position.x,state.turtle.position.y>;
		state.turtle.position = <state.turtle.position.x + toInt((eval(e, venv).r * cos((PI()/180) * state.turtle.dir)))
								,state.turtle.position.y + toInt((eval(e, venv).r * sin((PI()/180) * state.turtle.dir)))>;
		if(state.turtle.pendown){
                state.canvas = state.canvas + line(curLoc, state.turtle.position);
        }	
        return state;
}

State eval((Command)`back <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){
		curLoc = <state.turtle.position.x,state.turtle.position.y>;
		state.turtle.position = <state.turtle.position.x - toInt((eval(e, venv).r * cos((PI()/180) * state.turtle.dir)))
								,state.turtle.position.y - toInt((eval(e, venv).r * sin((PI()/180) * state.turtle.dir)))>;
		
		if(state.turtle.pendown){
                state.canvas = state.canvas + line(curLoc, state.turtle.position);
        }	
        return state;
}

State eval((Command)`home;` , FunEnv fenv, VarEnv venv, State state){
		curLoc = <state.turtle.position.x,state.turtle.position.y>;
		state.turtle.position = <0,0>; 
		//if(state.turtle.pendown){
             //   state.canvas = state.canvas + line(curLoc, state.turtle.position);
        //}	
        return state;
}
State eval((Command)`pendown;` , FunEnv fenv, VarEnv venv, State state){
		state.turtle.pendown = true;
        return state;
}
State eval((Command)`penup;` , FunEnv fenv, VarEnv venv, State state){
		state.turtle.pendown = false;
        return state;
}

State eval((Command)`right <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){
		int newDir = state.turtle.dir + toInt(eval(e, venv).r);
		if(newDir >= 360){
			newDir = newDir	- 360;
		}
		state.turtle.dir = newDir;
        return state;
}

State eval((Command)`left <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){
		int newDir = state.turtle.dir - toInt(eval(e, venv).r);
		if(newDir <= 0){
			newDir = newDir + 360;
		}
		state.turtle.dir = newDir;
        return state ;
}

//wat
State eval((Command)`to <FunId id> <VarId* args> <Command* commands> end` , FunEnv fenv, VarEnv venv, State state){
	 return state;
}

// Bind functions arguments to the expressions provided with the call
State eval((Command)`<FunId id> <Expr* exprs>;` , FunEnv fenv, VarEnv venv, State state){
     f = fenv[id];
     newVars = venv; //Make a copy. Scoping doesn't matter, I guess. Maybe if I try implementing assignment
	 println(exprs);

     for (varId <- f.args, expr <- exprs){//Wat am I even doing
    	newVars[varId] = eval(expr, venv);
     }  

	 for(c <- f.commands){
        state = eval(c, fenv, newVars, state); 
	 }

	 return state;
}

//test bool FunCall() = <<0,false,<0,0>>,[]>:=eval((Program)`to dash :n  right :n; pd; end dash 10;`, (), (), <<0,false,<0,0>>,[]>);
test bool FunCall() = <<0,false,<0,0>>,[]>:=eval((Program)`dash;`, (dash:(FunDef)`to dash :n  right :n; pd; end`), (), <<0,false,<0,0>>,[]>);

State eval((Block)`[ <Command* cmd> ]` , FunEnv fenv, VarEnv venv, State state){
	for (Command c <- cmd){
	 state = eval(c, fenv, venv, state);
	}
	return state;
}

State eval((Command)`repeat <Expr e> <Block b>`, FunEnv fenv, VarEnv venv, State state){
	int n = toInt(eval(e, venv).r);
    for(int I <- [1 .. n + 1]){
        state =  eval(b, fenv, venv, state);
    }
    return state;
}

State eval((Command)`ifelse <Expr e> <Block b1> <Block b2>`, FunEnv fenv, VarEnv venv, State state){
	if(eval(e, venv).b){
		return eval(b1, fenv, venv,state);
	} else{
		return eval(b2, fenv, venv, state);
	}
}

//Function Call

test bool d1() = <<10,false,<0,0>>,[]> := eval((Program)`to dash :n  right :n; pd ; end dash 1;`, (), (), <<0, false, <0,0>>,[]>);


//Logic
//And
Value eval((Expr)`<Expr l> && <Expr r>`, VarEnv env)
  = boolean (x && y)
  when
    boolean(x) := eval(l, env),
    boolean(y) := eval(r, env);
//Or
Value eval((Expr)`<Expr l> || <Expr r>`, VarEnv env)
  = boolean (x || y)
  when
    boolean(x) := eval(l, env),
    boolean(y) := eval(r, env);
//Comparison
//gte
Value eval((Expr)`<Expr l> \>= <Expr r>`, VarEnv env)
  = boolean (x >= y)
  when
    number(x) := eval(l, env),
    number(y) := eval(r, env);
//gte
Value eval((Expr)`<Expr l> \> <Expr r>`, VarEnv env)
  = boolean (x > y)
  when
    number(x) := eval(l, env),
    number(y) := eval(r, env);
//Eq
Value eval((Expr)`<Expr l>=<Expr r>`, VarEnv env)
  = boolean (x >= y)
  when
    x := eval(l, env),
    y := eval(r, env);
//not Eq
Value eval((Expr)`<Expr l>!=<Expr r>`, VarEnv env)
  = boolean (x != y)
  when
    x := eval(l, env),
    y := eval(r, env);
//Div
Value eval((Expr)`<Expr l> / <Expr r>`, VarEnv env)
  = number(x / y)
  when
    number(x) := eval(l, env),
    number(y) := eval(r, env);
//Multiplication
Value eval((Expr)`<Expr l> * <Expr r>`, VarEnv env)
  = number(x * y)
  when
    number(x) := eval(l, env),
    number(y) := eval(r, env);

//Plus
Value eval((Expr)`<Expr l> + <Expr r>`, VarEnv env)
  = number(x + y)
  when
    number(x) := eval(l, env),
    number(y) := eval(r, env);

//Minus
Value eval((Expr)`<Expr l> - <Expr r>`, VarEnv env)
  = number(x - y)
  when
    number(x) := eval(l, env),
    number(y) := eval(r, env);

//Number
Value eval((Expr)`<Number n>`, VarEnv env) = number(toReal(unparse(n)));
//True
Value eval((Expr)`true`, VarEnv venv){ return boolean(true);}
//False
Value eval((Expr)`false`, VarEnv venv){ return boolean(false);}
//Variable binding
Value eval((Expr)`<VarId x>`, VarEnv env) = env[x];

//Desugaring
test bool desugarTest () = (Program)`forward 10;` := desugar((Program)`fd 10;`); 
test bool desugarTest1 () = (Program)`ifelse true [ forward 10; ] []` := desugar((Program)`if true [ forward 10; ]`); 

//ControlFlow
test bool d1() = <<20,false,<0,0>>,[]> := eval((Command)`repeat 2[right 10;]`, (), (), <<0, false, <0,0>>,[]>);
test bool d5() = <<10,false,<0,0>>,[]> := eval((Command)`ifelse true [right 10;][]`, (), (), <<0, false, <0,0>>,[]>);

//Drawing
test bool d1() = <<10,false,<0,0>>,[]> := eval((Command)`right 10;`, (), (), <<0, false, <0,0>>,[]>);
test bool d2() = <<0,true,<0,0>>,[]> := eval((Command)`pendown;`, (), (), <<0, false, <0,0>>,[]>);
test bool d3() = <<0,false,<0,0>>,[]> := eval((Command)`penup;`, (), (), <<0, true, <0,0>>,[]>);
test bool d4() = <<180,false,<0,0>>,[]> := eval((Command)`home;`, (), (), <<180, false, <2,6>>,[]>);

//Values
test bool testVar() = eval((Expr)`:x`, ((VarId)`:x`: number(1.0))) == number(1.0); 

test bool testNumber() = eval((Expr)`2.0`, ()) == number(2.0);

test bool testBool() = eval((Expr)`true`, ()) == boolean(true);

test bool testMul() = eval((Expr)`:x * 2`, ((VarId)`:x`: number(2.0))) == number(4.0);

test bool testDiv() = eval((Expr)`:x / 2`, ((VarId)`:x`: number(4.0))) == number(2.0);

test bool testMin() = eval((Expr)`4.0 - 2.0`,()) == number(2.0);

test bool testPlus1() = eval((Expr)`:home + 2`, ((VarId)`:home`: number(4.0))) == number(6.0);
test bool testPlus() = eval((Expr)`:x + 2`, ((VarId)`:x`: number(4.0))) == number(6.0);