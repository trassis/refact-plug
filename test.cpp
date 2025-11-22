#include <iostream>

void add_twice(int &v, int w){
	v += w;
}

void vapo() {
	int a = 0;
	std::string s = "oi";
	for(int i=0; i<5; i++){
		a += i;
		s += "tchau";
	}
}

int main(){
	int nomecomx = 0;
	int y = 10;
	y += 1;
	int z = y + 2;

	vapo();

	std::cout << a << std::endl;

	return 0;
	// Long line: should give a code smell
	// asldkfjasldkjflaksdjfklasjdflkasjdfklajsdfklajsdflkajsdfkljasdlfjasdklasldkfjasdkfj
	// small line
	// asldkfjas
}
