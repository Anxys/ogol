module ogol::Eval

import ogol::Syntax;
import ogol::Canvas;
import ParseTree;

import String;
import util::Math;
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

// Top-level eval function
Canvas eval(p:(Program)`<Command* cmds>`){
	funenv = collectFunDefs(p);
	varEnv = ();
	state = <<0, false, <0,0>>,[]>;

	var desugared = desugar(p);	

	for (c <- desugared){
		state = eval(c, funenv, varEnv, state);
	}

	return state.canvas;
}


Program desugar(p:(Program)`<Command* cmds>`){
  return visit (p) {
  	case (ControlFlow)`if <Expr e> <Block b>` => (ControlFlow)`ifelse <Expr e> <Block b> []`
    case (Directions)`fd`=> (Directions)`forward`   
    case (Directions)`rt`=> (Directions)`right`   
    case (Directions)`lt`=> (Directions)`right`   
    case (Directions)`left`=> (Directions)`right`   
    case (Directions)`bk`=> (Directions)`back`   
    case (PenActions)`pu`=> (PenActions)`penup`   
    case (PenActions)`pd`=> (PenActions)`pendown`   
  };
}

FunEnv collectFunDefs(Program p) = (f.id : f| /FunDef f:= p);


State eval(Drawing cmd, FunEnv fenv, VarEnv venv, State state){
}

//sin(80)*fd = y  cos(80)* fd = x
State eval((Drawing)`forward <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){

}

State eval((Drawing)`back <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){
		
}

State eval((Drawing)`home;` , FunEnv fenv, VarEnv venv, State state){
        return <<state.turtle.dir, state.turtle.pendown, <0,0>>, state.canvas>;
}
State eval((PenActions)`pendown` , FunEnv fenv, VarEnv venv, State state){
        return <<state.turtle.dir, true, state.turtle.position>, state.canvas>;
}
State eval((PenActions)`penup` , FunEnv fenv, VarEnv venv, State state){
        return <<state.turtle.dir, false, state.turtle.position>, state.canvas>;
}
State eval((Drawing)`right <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){
        return <<state.turtle.dir + toInt(eval(e, venv).r), state.turtle.pendown, state.turtle.position>,state.canvas>;
}

State eval((Drawing)`left <Expr e> ;` , FunEnv fenv, VarEnv venv, State state){
        return <<state.turtle.dir - toInt(eval(e, venv).r), state.turtle.pendown, state.turtle.position>,state.canvas>;
}


State eval((FunCall)`to <Expr* exprs>;` , FunEnv fenv, VarEnv venv, State state){
	return for(e <- exprs); 
}

State eval((Block)`[ <Command* cmd> ]` , FunEnv fenv, VarEnv venv, State state){
	return for (c <- cmd){
		eval(c, fenv, venv, state);
	}
}

State eval((ControlFlow)`ifelse <Expr e> <Block b1> <Block b2>`, FunEnv fenv, VarEnv venv, State state){
	if(eval(e).b,varEnv){
		return eval(b1, fenv, varenv,state);
	} else{
		return eval(b2, varenv,state);
	}
}

State eval((Command) cmd, FunEnv fenv, VarEnv venv, State state){

}

int turn(State state, int i){
	return e + i;
}

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

//Drawing
test bool d1() = <<10,false,<0,0>>,[]> := eval((Drawing)`right 10;`, (), (), <<0, false, <0,0>>,[]>);
test bool d2() = <<0,true,<0,0>>,[]> := eval((PenActions)`pendown`, (), (), <<0, false, <0,0>>,[]>);
test bool d3() = <<0,false,<0,0>>,[]> := eval((PenActions)`penup`, (), (), <<0, true, <0,0>>,[]>);
test bool d4() = <<180,false,<0,0>>,[]> := eval((Drawing)`home;`, (), (), <<180, false, <2,6>>,[]>);

//Values
test bool testVar() = eval((Expr)`:x`, ((VarId)`:x`: number(1.0))) == number(1.0); 

test bool testNumber() = eval((Expr)`2.0`, ()) == number(2.0);

test bool testBool() = eval((Expr)`true`, ()) == boolean(true);

test bool testMul() = eval((Expr)`:x * 2`, ((VarId)`:x`: number(2.0))) == number(4.0);

test bool testDiv() = eval((Expr)`:x / 2`, ((VarId)`:x`: number(4.0))) == number(2.0);

test bool testDiv() = eval((Expr)`4.0 - 2.0`,()) == number(2.0);

test bool testDiv() = eval((Expr)`:x + 2`, ((VarId)`:x`: number(4.0))) == number(6.0);