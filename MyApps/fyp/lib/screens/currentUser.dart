class Currentuser {
  static String? userId;

  static void setUserId(String Id) {
    userId = Id;
  }

  static String? getUserId(){
    return userId;
  }
}