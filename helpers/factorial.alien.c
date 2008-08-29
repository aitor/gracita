
/*
=begin Adhearsion metadata

  name: Native Factorial
  author:
    name: Jay Phillips
    blog: http://jicksta.com
    email: Jicksta -at- Gmail.com
  gems:
    - soap4r
    - rubyinline: >= 0.8.2
  instructions: >
      Yes, this is a pure C file!!!
      This is an example of writing Adhearsion extensions in
      other languages. The first time this file is executed
      it will be compiled and the binary form will be cached.

      If your Adhearsion system is heavily dependent on
      an intensive helper, it may be advantageous to rewrite
      it in a language such as C or C++ and use it like this.

=end
*/

int fast_factorial(int input) {
  int prod = 1, count = 1;
  while(count <= input) {
    prod *= count++;
  }
  return prod;
}
