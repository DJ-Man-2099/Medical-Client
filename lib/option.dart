class Option{
  Function _f;
  Option(Function f){
    _f=f;
  }
  void run(){
    _f();
  }
}