module ogol::demo::basic::Reverse


public list[value] reverse0 ( list[value] l){

	return	for(int i <- [size(l)..-1]) append l[i - 1];
	
}



public bool isPalindrome(list[value] l){
	return for (int i <- [size(l)..-1]){
		append l[ i - 1];
	} == l;
}