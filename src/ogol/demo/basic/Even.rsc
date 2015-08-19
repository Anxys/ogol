module ogol::demo::basic::Even


public list[int] even0 (int max){	
	return for (int i <- [0..max], i % 2 ==0){
		append i;
	} 
}

public list[int] even2(int max){
	return [i | i<- [0..max], i % 2 ==0];
}

public list[int] allEvens (){
	list[int] evens = [];
	for (int i <- [0..u], i % 2 ==0)
		res += i;
	return evens;
}
